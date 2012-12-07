require 'orderedhash'
require 'fastercsv'
require_relative '../store/item'

module Store
  class Purchase
    attr_accessor :id, :item, :quantity, :seller, :buyer, :price
    @@last_id = 0
    @@purchases = []

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.item = nil
      self.quantity = -1
      self.seller = nil
      self.buyer = nil
    end

    def self.create(item, quantity, seller, buyer)
      purchase = Purchase.new
      purchase.item = item
      purchase.quantity = quantity
      purchase.seller = seller
      purchase.buyer = buyer
      purchase
    end

    def prepare
      # if buyer bought all items
      if self.item.quantity == self.quantity
        self.seller.release_item(self.item)
      else
        self.seller.release_quantity_of_item(self.item, self.quantity)
        self.item = self.item.clone
        self.item.id = Item.next_id!
        self.item.owner = nil
        self.item.quantity = self.quantity
        self.item.save
      end
      self.item.price = self.price unless self.price == nil
      self.item.state = :pending

      self.item.notify_change
      self.buyer.add_to_pending(self)
      self.buyer.credits -= self.item.price * self.quantity

      self.save
    end

    def set_to_offer(offer)
      self.price = offer.price
    end

    def confirm
      self.buyer.attach_item(self.item)

      TradingAuthority.settle_item_purchase(self.seller, self.item, self.quantity)

      self.buyer.delete_pending(self)
    end

    def save
      hash = OrderedHash.new
      hash[:item_name] = self.item.name
      hash[:price] = self.item.price
      hash[:from] = self.seller.name
      hash[:to] = self.buyer.name
      hash[:when] = Time.now

      @@purchases << hash
    end

    class << self
      def clear_id
        @@last_id = 0
      end

      def get_all_purchases
        @@purchases
      end

      # Get all purchases in the specified timeframe (format 'value[smhd]')
      def get_purchases_of_last(time_string)
        timeframe = Time.from_string time_string
        @@purchases.select {|purchase| purchase[:when] > Time.now - timeframe}
      end

      def dump(filename)
        FasterCSV.open(filename, "w") do |csv|
          csv << ["When", "Item", "Price", "From", "To"]
          @@purchases.each { |purchase|
            csv << [purchase[:when], purchase[:item_name], purchase[:price], purchase[:from], purchase[:to]]
          }
        end
      end
    end
  end
end