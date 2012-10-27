<<<<<<< HEAD
#superclass for user and organization
require 'bcrypt'
require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'

module Store
  class SystemUser
    attr_accessor :id, :name, :credits, :items, :description, :open_item_page_time, :image_path

    @@last_id = 0
    CREDIT_REDUCE_RATE = 0.05
	SELL_BONUS = 0.05

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

    # fetches SystemUser object, args must contain key :name or :id
    def self.fetch_by(args = {})
      return Store::User.fetch_by(args) if Store::User.exists?(args)
      return Store::Organization.fetch_by(args) if Store::Organization.exists?(args)
    end

    def self.by_id(id)
      return self.fetch_by(:id => id.to_i)
    end

    def self.by_name(name)
      return self.fetch_by(:name => name)
    end

    # return all system users
    def self.all
      return Store::User.all.concat(Store::Organization.all)
    end

    def self.exists?(args = {})
      return Store::User.exists?(args) || Store::Organization.exists?(args)
    end

    def self.reduce_credits
      all_users = self.all
      all_users.each{|user| user.reduce_credits }
    end

    def reduce_credits
      self.credits -= Integer(self.credits * CREDIT_REDUCE_RATE)
    end

    def propose_item(name, price, description = "", log = true)
      item = Item.named_priced_with_owner(name, price, self, description)
      item.save

      self.attach_item(item)

      Analytics::ItemAddActivity.with_creator_item(self, item).log if log

      return item
    end

    def get_active_items
      active_items = self.items.select {|i| i.active?}

      return active_items
    end

    def attach_item(item)
      self.items << item
      item.owner = self
    end

    def release_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    def delete_item(item_id, log = true)
      item = Store::Item.by_id(item_id)
      fail if item.nil?
      fail unless self.can_delete?(item)

      item.owner.release_item(item)
      item.delete

      Analytics::ItemDeleteActivity.with_remover_item(self, item).log if log
    end

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
      end

      seller.release_item(item)
      seller.credits += item.price + Integer(item.price * SELL_BONUS)

      item.deactivate

      self.attach_item(item)
      self.credits -= item.price

      item.notify_change

      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log

      return true, "Transaction successful"
    end

    def can_edit?(item)
      return item.editable_by?(self)
    end

    alias :can_delete? :can_edit?

    def can_buy?(item)
      return ((item.owner != self.on_behalf_of) && item.active?)
    end

    def can_activate?(item)
      return item.activatable_by?(self)
    end

    def to_s
      return "#{self.name}, #{self.credits}"
    end

    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
    end

    def is_organization?
      false
    end

    def send_money(amount)
      fail unless amount >= 0
      self.credits += amount
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
  end
end
