require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../helpers/security/string_checker'
require_relative '../store/comment'

module Store
  # The item is the central trading object within the application. It can be traded in between traders for a certain price.
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description, :edit_time, :image_path, :comments, :isFixed, :endTime, :increment, :bidders
    @@last_id = 0
    @@items = RBTree.new

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
      self.image_path = "/images/no_image.gif"
      self.edit_time = Time.now
      self.comments = []
      self.isFixed = true
      self.bidders = {}
    end

    # save item to system
    def save
      @@items[self.id] = self
    end

    # delete item from system
    def delete
      @@items.delete(self.id)
    end

    # updates newly created comments
    def update_comments(comment)
      self.comments << comment
    end

    # deletes a certain comment
    def delete_comment(comment)
      self.comments.delete(comment)
      comment.delete
    end

    # create a new item object for fixpriced sale with a name, price and owner
    def self.named_priced_with_owner_fixed(name, price, owner, description = "")
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      item.description = description
      item.isFixed = true
      item
    end

    # create a new item object for auction with a name, price and owner
    def self.named_priced_with_owner_auction(name, price, owner, increment, endTime, description = "")
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      item.description = description
      item.isFixed = false
      item.increment = increment
      item.endTime = endTime
      item
    end


    def to_s
      "#{self.name}, #{self.price}, #{self.owner}, #{self.active ? "active" : "inactive"}"
    end

    def activate
      self.active = true
    end

    def deactivate
      self.active = false
    end

    # update the item's status
    def update_status(new_status, log = true)
      old_status = self.active

      if old_status != new_status
        self.active = new_status

        self.notify_change
        Analytics::ItemStatusChangeActivity.with_editor_item_status(self.owner, self, new_status).log if log
      end
    end

    # returns whether the item is active or not
    def active?
      self.active
    end

    # returns whether the item is generally editable
    def editable?
      !self.active && (self.isFixed? || self.bidders.empty?)
    end

    # returns whether the item is editable by a certain trader
    def editable_by?(trader)
      self.editable? && self.owner.eql?(trader)
    end

    # returns whether the item is deletable by a certain user object
    alias :deletable_by? :editable_by?

    # returns whether the item is activatable by a certain user object
    def activatable_by?(trader)
      self.owner.eql?(trader)
    end

    def buyable_by?(trader)

      (!self.owner.eql?(trader) && self.active)
    end

    # update the item's properties, raises error if item is not editable
    def update(new_name, new_price, new_desc, log = true)
      fail unless self.editable?

      old_vals = {:name => self.name, :price => self.price, :description => self.description}
      new_vals = {:name => new_name, :price => new_price, :description => new_desc}

      if old_vals != new_vals
        self.name = new_name
        self.price = new_price
        self.description = new_desc

        self.notify_change
        Analytics::ItemEditActivity.with_editor_item_old_new_vals(self.owner, self, old_vals, new_vals).log if log
      end
    end

    # tell the item its properties have been changed
    def notify_change
      self.edit_time = Time.now
    end

    def isAuction?
      !self.isFixed
    end

    def isFixed?
      self.isFixed
    end

    # gets the highest Bidder/Amount pair out of bidders
    def highestBid
      maxBid = self.bidders.max_by{|k,v| v}
      {maxBid[0], maxBid[1]}
    end

    # gets the second highest Bidder/Amount pair out of bidders
    def secondInLineBid
      sorted = self.bidders.sort_by {|key, value| value}
      length = sorted.length.to_i
      {sorted[length-2][0], sorted[length-2][1]}
    end

    # the currentSellingPrice is the price you have to pay if you win the auction
    def currentSellingPrice
      if self.bidders.size == 0
        nil
      elsif self.bidders.size == 1
        self.price
      else
        self.secondInLineBid.values[0] + increment               #TODO
      end
    end

    # class methods
    class << self
      # deletes all items of an user
      def clear_all
        @@items.clear
      end

      # retrieve item object by id from system
      def by_id(id)
        @@items[id]
      end

      # get all stored items
      def all
        @@items.values.dup
      end

      def allFixed
        @@items.values.select{|val| val.isFixed?}.dup
      end

      def allAuction
        @@items.values.select{|val| val.isAuction?}.dup
      end

      # determines whether a string is a valid price for an item
      def valid_price?(price)
        Security::StringChecker.is_numeric?(price) && price.to_i >= 0
      end
    end
  end
end
