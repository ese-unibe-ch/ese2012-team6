module Store
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
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

    def to_s
      return "#{self.name}, #{self.price}, #{self.owner}, #{self.active ? "active" : "inactive"}"
    end

    def set_active
      self.active = true
    end

    def set_inactive
      self.active = false
    end

    def update_status(new_status)
      new_status = (new_status == "true")
      old_status = self.active

      if old_status != new_status
        self.active = new_status
        Analytics::ActivityLogger.log_activity(Analytics::ItemStatusChangeActivity.with_editor_item_status(self.owner, self.id, new_status))
      end
    end

    def active?
      return self.active
    end

    def editable?
      return (not self.active)
    end

    def update(name, price, desc)
      fail if not self.editable?

      old_vals = [self.name, self.price, self.description]
      new_vals = [name, price, desc]

      self.name = name
      self.price = price
      self.description = desc

      Analytics::ActivityLogger.log_activity(Analytics::ItemEditActivity.with_editor_item_old_new_vals(self.owner, self.id, old_vals, new_vals))
    end
  end
end
