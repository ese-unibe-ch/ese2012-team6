require 'rbtree'

module Store

  class Offer
    attr_accessor :item_name, :id, :price, :from, :quantity
    @@last_offer_id = 0
    @@offers = RBTree.new

    def initialize
      self.id = Offer.next_id!
      self.quantity = 1
    end

    # save offer to system
    def save
      @@offers[self.id] = self
    end

    # delete offer from system
    def delete
      @@offers.delete(self.id)
    end


       # create a new offer object
    def self.create(item_name, price,quantity, from)
      offer = Offer.new
      offer.item_name =item_name
      offer.price = price
      offer.from = from
      offer.quantity= quantity
      offer.save
      offer
    end


    # class methods
    class << self
      # retrieve offer object by id from system
      def by_id(id)
        @@offers[id]
      end

      # get all stored items
      def all
        @@offers.values.dup
      end

      # determines whether a string is a valid price for an item
      def valid_price?(price)
        Security::StringChecker.is_numeric?(price) && price.to_i > 0
      end

      def get_matching_items_count(user)
        offer_count = 0
        Store::Offer.all.each {|offer|
          offer_count += 1 if user.has_item_for_offer(offer)
        }
        offer_count
      end

      def next_id!
        @@last_offer_id += 1
      end

    end
  end
end
