require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'

module Store
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description, :edit_time, :image_path
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
      self.image_path = "/images/no_image.gif"
      self.edit_time = Time.now
    end

    def name=(name)
      @name = Security::String_Manager::destroy_script(name)
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

    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
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
        self.edit_time = Time.now
        Analytics::ActivityLogger.log_activity(Analytics::ItemStatusChangeActivity.with_editor_item_status(self.owner, self, new_status))
      end
    end

    def active?
      return self.active
    end

    def editable?
      return (not self.active)
    end

    def update(new_name, new_price, new_desc)

      fail unless self.editable?

      old_vals = {:name => self.name, :price => self.price, :description => self.description}
      new_vals = {:name => new_name, :price => new_price, :description => new_desc}

      if old_vals != new_vals
        self.name = new_name
        self.price = new_price
        self.description = new_desc
        self.edit_time = Time.now
        Analytics::ActivityLogger.log_activity(Analytics::ItemEditActivity.with_editor_item_old_new_vals(self.owner, self, old_vals, new_vals))
      end
    end
  end
end
