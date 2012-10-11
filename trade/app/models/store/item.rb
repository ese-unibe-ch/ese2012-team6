module Store
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description, :edit_time, :image_path
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
      self.image_path = "no_image.gif"
      self.edit_time = Time.now
    end

    def self.named_priced_with_owner(name, price, owner)
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      return item
    end

    def self.valid_price?(price)
      return (!!(price =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(price) >= 0)
    end

    def id_image_to_filename(id, path)
      if path == nil
        return "no_image.gif"
      end
      "#{id}_#{path}"
    end

    def to_s
      return "#{self.name}, #{self.price}, #{self.owner}, #{self.active ? "active" : "inactive"}"
    end

    #following 4 setters need to modify the edit_time. Therefore they are overwritten.
    def active=(anything)
      self.edit_time = Time.now
      @active = anything
    end

    def price=(anything)
      self.edit_time = Time.now
      @price = anything
    end

    def name=(anything)
      self.edit_time = Time.now
      @name = anything
    end

    def description=(anything)
      self.edit_time = Time.now
      @description = anything
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

    def editable?
      return (not self.active)
    end

  end
end
