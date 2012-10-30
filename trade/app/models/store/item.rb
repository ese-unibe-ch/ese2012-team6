require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../security/string_checker'
require_relative '../store/comment'

module Store
  # The item is the central trading object within the application. It can be traded in between users for a certain price.
  class Item
    attr_accessor :name, :id, :price, :owner, :active, :description, :edit_time, :image_path, :comments
    @@last_id = 0
    @@items = {}

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.active = false
      self.description = ""
      self.image_path = "/images/no_image.gif"
      self.edit_time = Time.now
      self.comments = []
    end

    # save item to system
    def save
      fail if @@items.has_key?(self.id)
      @@items[self.id] = self
      fail unless @@items.has_key?(self.id)
    end

    # delete item from system
    def delete
      fail unless @@items.has_key?(self.id)
      @@items.delete(self.id)
      fail if @@items.has_key?(self.id)
    end

    # updates newly created comments
    def update_comments(comment)
      self.comments << comment
    end

    # deletes a certain comment
    def delete_comment(comment)
      self.comments.delete(comment)
      comment.delete
    end

    # create a new item object with a name, price and owner
    def self.named_priced_with_owner(name, price, owner, description = "")
      item = Item.new
      item.name = name
      item.price = price
      item.owner = owner
      item.description = description
      item
    end

    def to_s
      "#{self.name}, #{self.price}, #{self.owner}, #{self.active ? "active" : "inactive"}"
    end

    # activate the item (you don't say...)
    def activate
      self.active = true
    end

    # deactivate the item (thanks captain obvious)
    def deactivate
      self.active = false
    end

    # update the item's status
    def update_status(new_status, log = true)

      new_status = (new_status == "true")
      old_status = self.active

      if old_status != new_status
        self.active = new_status

        self.notify_change
        Analytics::ItemStatusChangeActivity.with_editor_item_status(self.owner, self, new_status).log if log
      end
    end

    # returns whether the item is active or not
    def active?
      self.active
    end

    # returns whether the item is generally editable
    def editable?
      (not self.active)
    end

    # returns whether the item is editable by a certain user object
    def editable_by?(user)
      fail if user.nil?
      (self.editable? && ((self.owner.eql?(user)) || (self.owner.is_organization? && self.owner.has_admin?(user))))
    end

    # returns whether the item is deletable by a certain user object
    alias :deletable_by? :editable_by?

    # returns whether the item is activatable by a certain user object
    def activatable_by?(user)
      fail if user.nil?
      ((self.owner.eql?(user)) || (self.owner.is_organization? && self.owner.has_admin?(user)))
    end

    # update the item's properties
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

    # tell the item its properties have been changed
    def notify_change
      self.edit_time = Time.now
    end

    # class methods
    class << self
      # deletes all items of an user
      def clear_all
        @@items.clear
      end

      # retrieve item object by id from system
      def by_id(id)
        @@items[id]
      end

      # get all stored items
      def all
        @@items.values.dup
      end

      # determines whether a string is a valid price for an item
      def valid_price?(price)
        Security::StringChecker.is_numeric?(price) && price.to_i >= 0
      end
    end
  end
end
