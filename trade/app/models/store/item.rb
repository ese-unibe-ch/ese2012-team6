require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../security/string_checker'

module Store
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description, :edit_time, :image_path

    @@last_id = 0
    @@items = {}

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
      self.image_path = "/images/no_image.gif"
      self.edit_time = Time.now
    end

    # save item to system
    def save
      @@items[self.id] = self
    end

    # delete item from system
    def delete
      @@items.delete(self.id)
    end

    # retrieve item object by id from system
    def self.by_id(id)
      return @@items[id]
    end

    # get all stored items
    def self.all
      return @@items.values.dup
    end

    def name=(name)
      @name = Security::StringChecker.destroy_script(name)
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

    def activate
      self.active = true
    end

    def deactivate
      self.active = false
    end

    def update_status(new_status, log = true)

      new_status = (new_status == "true")
      old_status = self.active

      if old_status != new_status
        self.active = new_status

        self.notify_change
        Analytics::ItemStatusChangeActivity.with_editor_item_status(self.owner, self, new_status).log if log
      end
    end

    def active?
      return self.active
    end

    def editable?
      return (not self.active)
    end

    def update(new_name, new_price, new_desc, log = true)

      fail unless self.editable?

      old_vals = {:name => self.name, :price => self.price, :description => self.description}
      new_vals = {:name => new_name, :price => new_price, :description => new_desc}

      if old_vals != new_vals
        self.name = new_name
        self.price = new_price
        self.description = new_desc

        self.notify_change
        Analytics::ItemEditActivity.with_editor_item_old_new_vals(self.owner, self, old_vals, new_vals).log if log
      end
    end

    def notify_change
      self.edit_time = Time.now
    end
  end
end
