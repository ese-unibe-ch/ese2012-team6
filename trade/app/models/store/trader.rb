require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../helpers/security/mail_client'
require_relative '../store/trading_authority'
require_relative '../store/item'

# superclass for user and organization
# A Trader is the main actor in the system. The class provides services for trading items between users and creating new items.
# Keeps track of its own items
module Store
  class Trader
    @@last_id = 0

    attr_accessor :id, :name, :email, :credits, :items, :description, :open_item_page_time, :image_path
    @@pending_items = []

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
      equal_item = self.check_for_equal_item(name,price,description)
      if equal_item == nil
        item = self.propose_item(name,price,selling_mode,increment,end_time,description,log)
        item.quantity = quantity
      else
        equal_item.quantity += quantity
        item = equal_item
      end
      item
    end

    # propose a new item
    def propose_item(name, price, selling_mode, increment, end_time, description = "", log = true)
      if selling_mode == "fixed"
        item = Item.named_priced_with_owner_fixed(name, price, self, description)
      else
        item = Item.named_priced_with_owner_auction(name, price, self, increment.to_i, end_time, description)
      end
      item.save

      self.attach_item(item)
      Analytics::ItemAddActivity.with_creator_item(self, item).log if log

      item
    end

    # get a list of all active items of a user
    def get_active_items
      self.items.select { |i| i.active? }       #TODO only fixed or only auction
    end

    def attach_item(item)
      self.items << item
      item.owner = self
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

      Analytics::ItemDeleteActivity.with_remover_item(self, item).log if log
    end

    def self.all_pending_items
      @@pending_items
    end

    # adds the item to buy to the pending list
    def add_pending_item(item, user, quantity = 1, log = true)
      item.buyer = user
      seller = item.owner

      if seller.nil?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < (item.price * quantity)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "seller_not_own_item" #Seller does not own item to buy
      elsif quantity > item.quantity
        return false, "invalid_quantity" #Seller doesn't have enough items
      end

      if quantity == item.quantity
        item.pending_owner = item.owner
        seller.release_item(item)
        equal_item = self.check_for_equal_item(item.name, item.price, item.description)
        if equal_item == nil
          item.deactivate
          @@pending_items.push(item)
          user.credits -= item.price
          item.notify_change
        else
          equal_item.quantity += quantity
          equal_item.deactivate
          @@pending_items.push(item)
          user.credits -= item.price * quantity
          equal_item.notify_change
        end
      else
        item.pending_owner = item.owner
        @@pending_items.push(item)
        user.credits -= item.price * quantity
        seller.release_quantity_of_item(item, quantity)
        #new_item = self.propose_item_with_quantity(item.name, item.price, quantity, item.selling_mode, item.increment, item.end_time, item.description)
        #new_item.deactivate
      end
      #item.selling_mode = "pending"
    end

    # handles the shop of an item , returns true if buy process was successful, false otherwise
    def validate_item(item, quantity = 1, log = true)
      new_item = self.propose_item_with_quantity(item.name, item.price, quantity, item.selling_mode, item.increment, item.end_time, item.description)
      #new_item.deactivate(item)
      TradingAuthority.settle_item_purchase(item.pending_owner, item, quantity)
      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log
      @@pending_items.delete(item)
      item.selling_mode = "fixed"
      return true, "Transaction successful"
    end

    def buy_item(item, quantity = 1, log = true)
      seller = item.owner

      if seller.nil?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < (item.price * quantity)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "seller_not_own_item" #Seller does not own item to buy
      elsif quantity > item.quantity
        return false, "invalid_quantity" #Seller doesn't have enough items
      end

      if quantity == item.quantity
        seller.release_item(item)
        equal_item = self.check_for_equal_item(item.name, item.price, item.description)
        if equal_item == nil
          self.attach_item(item)
          item.deactivate
          item.notify_change
        else
          equal_item.quantity += quantity
          equal_item.deactivate
          equal_item.notify_change
        end
      else
        seller.release_quantity_of_item(item, quantity)
        new_item = self.propose_item_with_quantity(item.name, item.price, quantity, item.selling_mode, item.increment, item.end_time, item.description)
        new_item.deactivate
      end
      TradingAuthority.settle_item_purchase(seller, item, quantity)

      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log

      return true, "Transaction successful"
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

    def bid(item, amount)
      if canBid?(item, amount)
        previous_winner = item.current_winner
        previous_selling_price = item.currentSellingPrice

        if item.highestBid != nil
          previous_maxBid = item.bidders[previous_winner]
        else
          previous_maxBid = 0
        end
        item.bidders[self] = amount

        # reduce money if user is new winner, otherwise nothing happens
        current_winner = item.current_winner
        current_selling_price = item.currentSellingPrice

        if previous_winner != nil
          previous_winner.credits += previous_selling_price
        end
        current_winner.credits -= current_selling_price

        if previous_winner != nil && previous_winner != current_winner && previous_winner.email != nil
          # we got a new winner
          Security::MailClient.send_new_winner_mail(previous_winner.email, item)
        end
      end
    end

    def canBid?(item, amount)
      enoughMoneyForBid?(amount) && !sameBidExists?(item, amount) && amountBiggerThanCurrentSellingPrice(item, amount) && higherThanLastOwnBid?(item, amount)
    end

    def amountBiggerThanCurrentSellingPrice(item, amount)
      if item.currentSellingPrice != nil
        amount >= item.currentSellingPrice
      else
        amount >= item.price
      end
    end

    def enoughMoneyForBid?(amount)
      self.credits >= amount
    end

    def sameBidExists?(item, amount)
      item.bidders.has_value?(amount)
    end

    def higherThanLastOwnBid?(item, amount)
      if (self.alreadyBade?(item))
        amount >= item.bidders[self]+item.increment  #higher than last own bid
      else
        true
      end
    end

    def alreadyBade?(item)
      item.bidders[self] != nil
    end

    def check_for_equal_item(name, price, description)
      index = items.index {|x| x.name.eql?(name) and x.price.eql?(price) and x.description.eql?(description)}
      return items[index] unless index == nil
    end

    # class methods
    class << self
      # deletes all users and organizations from the system
      def clear_all
        @@last_id = 0
        User.clear_all
        Organization.clear_all
      end

      # returns the trader found by name
      def by_name(name)
        return User.by_name(name) if User.exists?(name)
        Organization.by_name(name) if Organization.exists?(name)
      end

      # returns all traders
      def all
        User.all.concat(Organization.all).sort { |a,b| a.id <=> b.id }
      end

      # returns true if the system includes a certain trader with the name specified
      def exists?(name)
        User.exists?(name) || Organization.exists?(name)
      end
    end
  end
end
