module Store
  class Item
    attr_accessor :name, :id, :price, :owner, :active
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
    end

    def self.named_priced_with_owner(name, price, owner)
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      return item
    end

    def to_s
      return "#{self.name}, #{self.price}, #{self.owner}, #{self.active ? "active" : "inactive"}"
    end

    def set_active
      self.active = true
    end

    def set_inactive
      self.active = false
    end

    def active?
      return self.active
    end

  end
end
