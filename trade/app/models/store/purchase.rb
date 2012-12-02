require_relative '../store/item'

module Store
  class Purchase
    attr_accessor :id, :item, :quantity, :seller, :buyer
    @@last_id = 0

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
      self.item.state = :pending

      self.item.notify_change
      self.buyer.add_to_pending(self)
      self.buyer.credits -= self.item.price * self.quantity
    end

    def confirm
      self.buyer.attach_item(self.item)

      TradingAuthority.settle_item_purchase(self.seller, self.item, self.quantity)

      self.buyer.delete_pending(self)
    end

    class << self
      def clear_id
        @@last_id = 0
      end
    end
  end
end