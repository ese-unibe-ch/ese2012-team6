require 'bcrypt'
require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/trading_authority'
require_relative '../store/item'

# superclass for user and organization
# A SystemUser is the main actor in the system. The class provides services for trading items between users and creating new items
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

    # creates a new system user object, options include :description and :credits
    def self.named(name, options = {})
      system_user = SystemUser.new

      system_user.name = name
      system_user.description = options[:description] || ""
      system_user.credits = options[:credits] || 0

      system_user
    end

    # propose a new item
    def propose_item(name, price, description = "", log = true)
      item = Item.named_priced_with_owner(name, price, self, description)
      item.save
      self.attach_item(item)
      Analytics::ItemAddActivity.with_creator_item(self, item).log if log

      item
    end

    # s all active items of an user
    def get_active_items
      self.items.select { |i| i.active? }
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

    # deletes chosen item, raises error if user can not delete item
    def delete_item(item_id, log = true)
      item = Item.by_id(item_id)

      fail if item.nil?
      fail unless self.can_delete?(item)

      item.owner.release_item(item)
      item.delete

      Analytics::ItemDeleteActivity.with_remover_item(self, item).log if log
    end

    # handles the shop of an item , returns true if buy process was successfull, false otherwise
    # also returns error code
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

      TradingAuthority.settle_item_purchase(seller, self, item)

      item.deactivate
      self.attach_item(item)

      item.notify_change

      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log

      return true, "Transaction successful"
    end

    # returns true if an user is allowed to edit
    def can_edit?(item)
      item.editable_by?(self)
    end

    alias :can_delete? :can_edit?

    # returns true if user is allowed to buy
    def can_buy?(item)
      ((item.owner != self.on_behalf_of) && item.active?)
    end

    # returns true if user is allowed to activate an item
    def can_activate?(item)
      item.activatable_by?(self)
    end

    # returns the system user as a string
    def to_s
      "#{self.name}, #{self.credits}"
    end

    def is_organization?
      false
    end

    # sends a certain amount of money from the user/org to a another user/org
    def send_money_to(receiver, amount)
      fail if receiver.nil?
      return false unless self.credits >= amount

      self.credits -= amount
      receiver.send_money(amount)

      fail if self.credits < 0

      true
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
      !(self.open_item_page_time < item.edit_time)
    end

    # class methods
    class << self
      # deletes all users and organizations from the system
      def clear_all
        @@last_id = 0
        User.clear_all
        Organization.clear_all
      end

      # fetches system user object, args must contain key :name or :id
      # returns nil if not found
      def fetch_by(args = {})
        return User.fetch_by(args) if User.exists?(args)
        Organization.fetch_by(args) if Organization.exists?(args)
      end

      # returns the system user found by id
      def by_id(id)
        fetch_by(:id => id.to_i)
      end

      # returns the system user found by name
      def by_name(name)
        fetch_by(:name => name)
      end

      # returns all system users
      def all
        User.all.concat(Organization.all)
      end

      # returns true if the system includes a certain user or organization object, args must include keys :id xor :name
      def exists?(args = {})
        User.exists?(args) || Organization.exists?(args)
      end
    end
  end
end
