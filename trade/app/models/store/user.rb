module Store
  class User
    attr_accessor :name, :credits, :items

    def initialize
      self.name = ""
      self.credits = 100
      self.items = []
    end

    def self.named(name)
      user = User.new
      user.name = name
      return user
    end

    def propose_item(name, price)
      item = Item.named_priced_with_owner(name, price, self)
      self.items << item
      return item
    end

    def get_active_items
      active_items = self.items.select {|i| i.active?}

      return active_items
    end

    def add_item(item)
      self.items << item
      item.owner = self
    end

    def remove_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    def buy_item(item)
      seller = item.owner

      if seller.nil?
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < item.price
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        return false, "seller_not_own_item" #Seller does not own item to buy
      end

      seller.remove_item(item)
      seller.credits += item.price

      item.owner = self
      item.set_inactive

      self.add_item(item)
      self.credits -= item.price

      return true, "Transaction successful"
    end

    def to_s
      return "#{self.name}, #{self.credits}"
    end
  end
end
