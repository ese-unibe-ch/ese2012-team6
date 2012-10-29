require 'bcrypt'
require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'

# superclass for user and organization
# responsible for all actions concerning user and organization objects
module Store
  class SystemUser
    attr_accessor :id, :name, :credits, :items, :description, :open_item_page_time, :image_path

    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.name = ""
      self.credits = 0
      self.items = []
      self.description = ""
      self.open_item_page_time = Time.now
      self.image_path = "/images/no_image.gif"
    end

    # creates a new system user object
    def self.named(name, options = {})
      system_user = SystemUser.new

      system_user.name = name
      system_user.description = options[:description] || ""
      system_user.credits = options[:credits] || 0

      return system_user
    end

    # deletes all users and organizations from the system
    def self.clear_all
      @@last_id = 0
      User.clear_all
      Organization.clear_all
    end

    # fetches system user object, args must contain key :name or :id
    def self.fetch_by(args = {})
      return User.fetch_by(args) if User.exists?(args)
      return Organization.fetch_by(args) if Organization.exists?(args)
    end

    # returns the system user found by id
    def self.by_id(id)
      return self.fetch_by(:id => id.to_i)
    end

    # returns the system user found by name
    def self.by_name(name)
      return self.fetch_by(:name => name)
    end

    # returns all system users
    def self.all
      return User.all.concat(Organization.all)
    end

    # returns true if the system includes a certain user or organization object
    def self.exists?(args = {})
      return User.exists?(args) || Organization.exists?(args)
    end

    # propose a new item
    def propose_item(name, price, description = "", log = true)
      item = Item.named_priced_with_owner(name, price, self, description)
      item.save
      self.attach_item(item)
      Analytics::ItemAddActivity.with_creator_item(self, item).log if log

      return item
    end

    # returns all active items of an user
    def get_active_items
      active_items = self.items.select {|i| i.active?}
      return active_items
    end

    # attaches a newly created or bought item
    def attach_item(item)
      self.items << item
      item.owner = self
    end

    # deletes the owner of an item to release it
    def release_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    # deletes chosen item
    def delete_item(item_id, log = true)
      item = Item.by_id(item_id)
      fail if item.nil?
      fail unless self.can_delete?(item)

      item.owner.release_item(item)
      item.delete

      Analytics::ItemDeleteActivity.with_remover_item(self, item).log if log
    end

    # handles the shop of an item
    def buy_item(item, log = true)
      seller = item.owner

      if seller.nil?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < item.price
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "seller_not_own_item" #Seller does not own item to buy
      elsif !self.knows_item_properties?(item)
        return false, "item_changed_details" #Buyer is not aware of latest changes to item's properties
      end

      seller.release_item(item)
      seller.credits += item.price + Integer(item.price * TradingAuthority::SELL_BONUS)

      item.deactivate

      self.attach_item(item)
      self.credits -= item.price

      item.notify_change

      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log

      return true, "Transaction successful"
    end

    # returns true if an user is allowed to edit
    def can_edit?(item)
      return item.editable_by?(self)
    end

    alias :can_delete? :can_edit?

    # returns true if user is allowed to buy
    def can_buy?(item)
      return ((item.owner != self.on_behalf_of) && item.active?)
    end

    # returns true if user is allowed to activate an item
    def can_activate?(item)
      return item.activatable_by?(self)
    end

    # returns the system user as a string
    def to_s
      return "#{self.name}, #{self.credits}"
    end

    # finds an image by id and path
    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
    end

    # returns false when a system user object calls this method
    def is_organization?
      false
    end

    # sends a certain amount of money from the user to a certain organization
    def send_money_to(receiver, amount)
      fail if receiver.nil?
      return false unless self.credits >= amount

      self.credits -= amount
      receiver.send_money(amount)

      fail if self.credits < 0

      return true
    end

    # making the transfer of credit
    def send_money(amount)
      fail unless amount >= 0
      self.credits += amount
    end

    # save time for item page
    def acknowledge_item_properties!
      self.open_item_page_time = Time.now
    end

    # returns true when user is aware of latest changes to item, false otherwise
    def knows_item_properties?(item)
      return !(self.open_item_page_time < item.edit_time)
    end
  end
end
