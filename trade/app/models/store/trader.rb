require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../helpers/security/mail_dispatcher'
require_relative '../store/trading_authority'
require_relative '../store/item'
require_relative '../store/purchase'
require_relative '../helpers/exceptions/trade_error'

# superclass for user and organization
# A Trader is the main actor in the system. The class provides services for trading items between users and creating new items.
# Keeps track of its own items
module Store
  class Trader
    include Exceptions
    include Analytics

    @@last_id = 0

    attr_accessor :id, :name, :email, :credits, :items, :description, :open_item_page_time, :image_path, :pending_purchases, :state

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.name = ""
      self.email = ""
      self.credits = 0
      self.items = []
      self.description = ""
      self.open_item_page_time = Time.now
      self.image_path = "/images/no_image.gif"
      self.pending_purchases = []
	    self.state = :active
    end

    # creates a new trader object, options include :description and :credits
    def self.named(name, options = {})
      trader = Trader.new

      trader.name = name
      trader.description = options[:description] || ""
      trader.credits = options[:credits] || 0

      trader
    end

    # propose a new item with quantity
    def propose_item_with_quantity(name, price, quantity, selling_mode, increment, end_time, description = "", log = true)
      item = self.propose_item(name,price,selling_mode,increment,end_time, quantity, description,log)
      item
    end

    # propose a new item
    def propose_item(name, price, selling_mode, increment, end_time, quantity = 1, description = "", log = true)
      if selling_mode == :fixed
        item = Item.fixed(name, price, self, description)
      elsif selling_mode == :auction
        item = Item.auction(name, price, self, increment.to_i, end_time, description)
      end
      item.quantity = quantity
      item.save

      self.attach_item(item)
      ItemAddActivity.create(self, item).log if log

      item
    end

    # get a list of all active items of a user
    def get_active_items
      self.items.select { |i| i.active? }       #TODO only fixed or only auction
    end

    # attach a bought item
    def attach_item(item)
      equal_item = self.check_for_equal_item(item.name,item.price,item.description)
      if equal_item == nil
        self.items << item
        item.owner = self
        item.deactivate
      else
        equal_item.quantity += item.quantity
        equal_item.deactivate
        item.delete
      end
    end

    # releases a certain quantity of an item
    def release_quantity_of_item(item, quantity)
      if self.items.include?(item)
        item.quantity -= quantity
      end
    end

    # deletes the owner of an item to release it
    def release_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    # deletes chosen item, raises error if trader can not delete item
    def delete_item(item_id, log = true)
      item = Item.by_id(item_id)

      fail if item.nil?
      fail unless self.can_delete?(item)

      item.owner.release_item(item)
      item.delete

      ItemDeleteActivity.create(self, item).log if log
    end

    # Purchase the indicated amount of the indicated item. PurchaseError will be raised if an error occured.
    # Returns purchase reference if purchase was successful
    def purchase(item, quantity = 1, log = true)
      seller = item.owner
      purchased_item = item

      if seller.nil?
        PurchaseActivity.failed(self, purchased_item, quantity).log if log
        raise TradeError, "ITEM_NO_OWNER" #Item does not belong to anybody
      elsif quantity > purchased_item.quantity
        PurchaseActivity.failed(self, purchased_item, quantity).log if log
        raise TradeError, "INVALID_QUANTITY" #Seller doesn't have enough items
      elsif !purchased_item.active?
        PurchaseActivity.failed(self, purchased_item, quantity).log if log
        raise TradeError, "BUY_INACTIVE_ITEM" #Trying to buy inactive item
      elsif !seller.items.include?(purchased_item)
        PurchaseActivity.failed(self, purchased_item, quantity).log if log
        raise TradeError, "SELLER_NOT_ITEM_OWNER" #Seller does not own item to buy
      elsif self.credits < (purchased_item.price * quantity)
        PurchaseActivity.failed(self, purchased_item, quantity).log if log
        raise TradeError, "NOT_ENOUGH_CREDITS" #Buyer does not have enough credits
      end

      purchase = Purchase.create(item, quantity, seller, self)
      purchase.prepare

      PurchaseActivity.successful(purchase).log if log

      purchase
    end

    # confirm a previously prepared purchase
    def confirm_purchase(purchase)
      purchase.confirm
    end

    # confirms all pending purchases
    def confirm_all_pending_purchases
      self.pending_purchases.each{|purchase| purchase.confirm}
    end

    # add purchase to user's pending purchases list
    def add_to_pending(purchase)
      self.pending_purchases.push(purchase)
    end

    # delete purchase from user's pending purchases list
    def delete_pending(purchase)
      self.pending_purchases.delete(purchase)
    end

    # returns true if an user is allowed to edit
    def can_edit?(item)
      item.editable_by?(self)
    end

    alias :can_delete? :can_edit?

    # returns true if user is allowed to buy item
    def can_buy?(item)
      item.buyable_by?(self)
    end

    # returns true if user is allowed to activate an item
    def can_activate?(item)
      item.activatable_by?(self)
    end

    # returns the system user as a string
    def to_s
      "#{self.name}, #{self.credits}"
    end

    # sends a certain amount of money from the user/org to a another user/org. Raises TradeException if operation failed
    def transfer_credits_to(receiver, amount)
      fail if receiver.nil?
      raise TradeError, "NOT_ENOUGH_CREDITS " unless self.credits >= amount

      self.credits -= amount
      receiver.credits += amount
    end

    # save time for item page
    def acknowledge_item_properties!
      self.open_item_page_time = Time.now
    end

    # returns true when user is aware of latest changes to item, false otherwise
    def knows_item_properties?(item)
      !(self.open_item_page_time < item.edit_time)
    end

    def bid(item, amount)
      if can_bid?(item, amount)
        previous_winner = item.current_winner
        previous_selling_price = item.bidders[previous_winner]

        if item.highest_bid != nil
          previous_max_bid = item.bidders[previous_winner]
        else
          previous_max_bid = 0
        end
        item.bidders[self] = amount

        # reduce money if user is new winner, otherwise nothing happens
        current_winner = item.current_winner
        current_max_bid = item.bidders[current_winner]

        if previous_winner != nil
          previous_winner.credits += previous_max_bid
        end
        current_winner.credits -= current_max_bid

        if previous_winner != nil && previous_winner != current_winner && previous_winner.email != nil
          # we got a new winner
          #Security::MailDispatcher.send_new_winner_mail(previous_winner.email, item)
        end
      else
        raise TradeError, "INVALID_BID" #Bid is too small or already exists or user doesn't have enough money.
      end
    end

    def can_bid?(item, amount)
      enough_money_for_bid?(item, amount) && !same_bid_exists?(item, amount) && amount_bigger_than_current_selling_price(item, amount) && higher_than_last_own_bid?(item, amount)
    end

    def amount_bigger_than_current_selling_price(item, amount)
      if item.current_selling_price != nil
        amount >= item.current_selling_price + item.increment
      else
        amount >= item.price
      end
    end

    def enough_money_for_bid?(item, amount)
      if item.current_winner == self
        self.credits + item.bidders[self] >= amount
      else
        self.credits >= amount
      end
    end

    def same_bid_exists?(item, amount)
      item.bidders.has_value?(amount)
    end

    def higher_than_last_own_bid?(item, amount)
      if self.already_bade?(item)
        amount >= item.bidders[self]+item.increment  #higher than last own bid
      else
        true
      end
    end

    def already_bade?(item)
      item.bidders[self] != nil
    end

    def check_for_equal_item(name, price, description, item_not_to_compare = nil)
      index = items.index {|x| x.name.eql?(name) and x.price.eql?(price) and x.description.eql?(description) and x != item_not_to_compare}
      return items[index] unless index == nil
    end

    def non_pending_items
      return self.items.select {|item| item.state != :pending}
    end

    def comment(item, text)
      comment = Comment.new_comment(text, self)
      item.update_comments(comment)
    end

    # class methods
    class << self
      # deletes all users and organizations from the system
      def clear_all
        @@last_id = 0
        User.clear_all
        Organization.clear_all
        Purchase.clear_id
      end

      # returns the trader found by name
      def by_name(name)
        return User.by_name(name) if User.exists?(name)
        Organization.by_name(name) if Organization.exists?(name)
      end

      # returns all traders
      def all
        User.all_active.concat(Organization.all).sort { |a,b| a.id <=> b.id }
      end

      # returns true if the system includes a certain trader with the name specified
      def exists?(name)
        User.exists?(name) || Organization.exists?(name)
      end
    end
  end
end
