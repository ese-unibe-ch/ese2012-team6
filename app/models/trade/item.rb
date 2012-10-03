module Trade
  #Except of the user, items are the most important objects in the trade.
  #They can be sold and bought from the users, if they are listed in the
  #list of all active items.

  class Item

    @@items = Array.new
    @@id_count = 0

    attr_accessor :id, :name, :price, :active, :owner

    def self.named( name, price, owner)
      item = self.new
      item.id = @@id_count
      @@id_count += 1
      item.name = name
      item.price = price
      item.owner = owner
      item
    end

    def self.all
      @@items
    end

    def self.all_active
      active_items = @@items.clone
      active_items.delete_if {|item| !item.active}
      active_items
    end

    def save
      @@items.push(self)
    end

    def initialize
      self.active = false
    end

    #This function activates an item, which now is able to be sold.
    def activate
      self.active = true
    end

    #This functions deactivates an item, which now is disabled.
    def deactivate
      self.active = false
    end

    def to_s
      "#{id}: #{name} for #{price}$"
    end

    def equal?(item)
      self.id == item.id
    end

  end

end