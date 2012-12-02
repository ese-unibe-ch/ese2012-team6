require 'rbtree'
require 'parsedate'
require 'json'
require 'orderedhash'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../helpers/security/string_checker'
require_relative '../helpers/converter/converter'
require_relative '../helpers/time/time_helper'
require_relative '../store/comment'

module Store
  # The item is the central trading object within the application. It can be traded in between traders for a certain price.
  class Item
    attr_accessor :name, :id, :price, :owner, :state, :description, :edit_time, :image_path,
                  :comments, :selling_mode, :end_time, :increment, :bidders, :quantity
    @@last_id = 0
    @@items = RBTree.new

    def initialize
      self.id = Item.next_id!
      self.state = :inactive
      self.description = ""
      self.image_path = "/images/no_image.gif"
      self.edit_time = Time.now
      self.comments = []
      self.selling_mode = :fixed
      self.bidders = {}
      self.quantity = 1
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
    def self.fixed(name, price, owner, description = "")
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      item.description = description
      item.selling_mode = :fixed
      item
    end

    # create a new item object for auction with a name, price and owner
    def self.auction(name, price, owner, increment, endTime, description = "")
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      item.description = description
      item.selling_mode = :auction
      item.increment = increment != nil ? increment.to_i : nil
      item.end_time = endTime
      item
    end

    def end_time=(end_time)
      if end_time != nil && end_time != ""
        if end_time.is_a?(Fixnum)
          @end_time = DateTime.now + end_time
        elsif end_time.is_a?(String)
          @end_time = Time.mktime(*ParseDate.parsedate(end_time)).to_datetime
        elsif end_time.is_a?(DateTime)
          @end_time = end_time
        end
      else
        @end_time = nil
      end    
    end

    def to_s
      "#{self.name}, #{self.price}, #{self.owner.name}, #{self.state}"
    end

    #activates item with end_time, if end_time is set else activates normally
    def activate_with_end_time(new_end_time)
      self.end_time = new_end_time
      self.update_status(:active)
    end

    def activate
      self.state = :active
    end

    def deactivate
      self.state = :inactive
      if self.is_auction?
        # pay money back
        if !self.is_finished?
          buyer = self.current_winner
          if buyer != nil
            buyer.credits += self.bidders[buyer]
          end
        end
        self.bidders = {}

      end
    end

    # update the item's status
    def update_status(new_status, log = true)
      old_status = self.state

      if old_status != new_status
        self.state = new_status ? :active : :inactive

        self.notify_change
        Analytics::ItemStatusChangeActivity.create(self.owner, self, new_status).log if log
      end
    end

    # returns whether the item is active or not
    def active?
      self.state == :active
    end

    # returns whether the item is generally editable
    def editable?
      !self.active? && (self.is_fixed? || self.bidders.empty?)
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
      (!self.owner.eql?(trader) && self.active?)
    end

    # update the item's properties, raises error if item is not editable
    def update(new_name, new_price, new_desc, new_selling_mode, new_increment, new_end_time, log = true)
      fail unless self.editable?

      old_vals = {:name => self.name, :price => self.price, :description => self.description,
        :selling_mode => self.selling_mode, :increment => self.increment, end_time => self.end_time}
      new_vals = {:name => new_name, :price => new_price, :description => new_desc,
        :selling_mode => new_selling_mode, :increment => new_increment != nil ? new_increment.to_i : nil, end_time => new_end_time}

      if old_vals != new_vals
        self.name = new_name
        self.price = new_price
        self.description = new_desc
        self.selling_mode = new_selling_mode
        self.increment = new_increment != nil ? new_increment.to_i : nil
        self.end_time = new_end_time

        self.notify_change
        Analytics::ItemEditActivity.create(self.owner, self, old_vals, new_vals).log if log

        unless self.owner == nil
         equal_item = self.owner.check_for_equal_item(new_name, new_price, new_desc, self)
          if equal_item != nil
            equal_item.quantity += self.quantity
            owner.items.delete(self)
            return equal_item.id
          end
        end
      end
      return self.id
    end

    # tell the item its properties have been changed
    def notify_change
      self.edit_time = Time.now
    end

    def is_auction?
      self.selling_mode == :auction
    end

    def is_fixed?
      self.selling_mode == :fixed
    end

    # gets the highest Bidder/Amount pair out of bidders
    def highest_bid
      sorted = self.bidders.sort_by {|key, value| value}
      length = sorted.length.to_i
      if length < 1
        nil
      else
        {sorted[length-1][0], sorted[length-1][1]}
      end
    end

    # gets the second highest Bidder/Amount pair out of bidders
    def second_in_line_bid
      sorted = self.bidders.sort_by {|key, value| value}
      length = sorted.length.to_i
      if length < 2
        nil
      else
        {sorted[length-2][0], sorted[length-2][1]}
      end
    end

    # the current_selling_price is the price you have to pay if you win the auction
    def current_selling_price
      if self.bidders.size == 0
        nil
      elsif self.bidders.size == 1
        self.price
      else
        (self.secondInLineBid.values[0].to_i + increment.to_i > self.highestBid.values[0].to_i ? self.highestBid.values[0].to_i : self.secondInLineBid.values[0].to_i + increment.to_i)
      end
    end

    def current_auction_price_to_show
      if self.current_selling_price == nil
        self.price
      else
        self.current_selling_price
      end
    end

    def current_winner
      highest_bid = self.highest_bid
      highest_bid != nil ? highest_bid.keys[0] : nil
    end

    def is_finished?
      time_delta < 0
    end
    
    def time_delta
      current_time = DateTime.now
      ((self.end_time - current_time) * 24 * 60 * 60).to_i
    end
    
    def time_delta_string
      Converter::TimeConverter.convert_seconds_to_string self.time_delta
    end

    def clone
      copy = Item.new
      copy.id = self.id
      copy.name = self.name
      copy.price = self.price
      copy.owner = self.owner
      copy.description = self.description
      copy.edit_time = self.edit_time
      copy.image_path = self.image_path
      copy.comments = self.comments.dup
      copy
    end

    def to_json(*opt)
      hash = OrderedHash.new

      hash[:id] = self.id
      hash[:name] = self.name
      hash[:price] = self.price
      hash[:quantity] = self.quantity
      hash[:owner] = self.owner.name if self.state != :pending
      hash[:state] = self.state
      hash[:image_url] = self.image_path

      hash.to_json(*opt)
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
        @@items.values.select{|val| val.is_fixed? && val.state != :pending}.dup
      end
	  
      def allFixed_of_active_users
        all_fixed_items = self.allFixed
        all_fixed_items.select {|a| a.owner.state == :active}
      end

      def allAuction
        @@items.values.select{|val| val.is_auction?}.dup
      end

	  def allAuction_of_active_users
        all_auction_items = self.allAuction
        all_auction_items.select{|a| a.owner.state == :active}
      end

      # determines whether a string is a valid price for an item
      def valid_price?(price)
        Security::StringChecker.is_numeric?(price) && price.to_i > 0
      end

      def next_id!
        @@last_id += 1
      end
    end
  end
end
