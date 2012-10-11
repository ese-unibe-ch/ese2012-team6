module Analytics
  module ActivityType
    ITEM_BUY = "ItemBuy"
    ITEM_EDIT = "ItemEdit"
    ITEM_ADD = "ItemAdd"
    ITEM_STATUS_CHANGE = "ItemStatusChange"
    ITEM_DELETE = "ItemDelete"
    NONE = "None"
  end

  class Activity
    attr_accessor :id, :type, :timestamp, :actor_name, :item_id, :item_name
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.type = ActivityType::NONE
      self.actor_name = ""
      self.item_id = -1
      self.item_name = ""
      self.timestamp = Time.now.getutc
    end

    def what_happened
      return "Nothing"
    end

  end

  class ItemBuyActivity < Activity
    attr_accessor :price

    def initialize
      super
      self.type = ActivityType::ITEM_BUY
      self.price = -1
    end

    def self.with_buyer_item_price(buyer, item)
      buy_activity = ItemBuyActivity.new

      buy_activity.actor_name = buyer.name
      buy_activity.item_id = item.id
      buy_activity.item_name = item.name
      buy_activity.price = item.price

      return buy_activity
    end

    def what_happened
      return "User #{self.actor_name} bought item ##{self.item_id} #{self.item_name} for #{self.price}$"
    end
  end

  class ItemEditActivity < Activity
    attr_accessor :old_values, :new_values

    def initialize
      super
      self.type = ActivityType::ITEM_EDIT
      self.old_values = []
      self.new_values = []
    end

    def self.with_editor_item_old_new_vals(editor, item, old_vals, new_vals)
      edit_activity = ItemEditActivity.new

      edit_activity.actor_name = editor.name
      edit_activity.item_id = item.id
      edit_activity.item_name = item.name
      edit_activity.old_values = old_vals
      edit_activity.new_values = new_vals

      return edit_activity
    end

    def what_happened
      return "User #{self.actor_name} edited item ##{self.item_id} #{self.item_name}"
    end
  end


  class ItemAddActivity < Activity

    def initialize
      super
      self.type = ActivityType::ITEM_ADD
    end

    def self.with_creator_item(creator, item)
      add_activity = ItemAddActivity.new

      add_activity.actor_name = creator.name
      add_activity.item_id = item.id
      add_activity.item_name = item.name
     
      return add_activity
    end

    def what_happened
      return "User #{self.actor_name} added item ##{self.item_id} #{self.item_name}"
    end
  end

  class ItemStatusChangeActivity < Activity
    attr_accessor :new_status

    def initialize
      super
      self.type = ActivityType::ITEM_STATUS_CHANGE
      self.new_status = nil
    end

    def self.with_editor_item_status(editor, item, new_status)
      status_change_activity = ItemStatusChangeActivity.new

      status_change_activity.actor_name = editor.name
      status_change_activity.item_id = item.id
      status_change_activity.item_name = item.name
      status_change_activity.new_status = new_status

      return status_change_activity
    end

    def what_happened
      return "User #{self.actor_name} changed status of item ##{self.item_id} #{self.item_name} to #{self.new_status ? "active" : "inactive"}"
    end
  end

  class ItemDeleteActivity < Activity
    attr_accessor :remover_name, :item_id, :item_name

    def initialize
      super
      self.type = ActivityType::ITEM_DELETE
    end

    def self.with_remover_item(remover, item)
      delete_activity = ItemDeleteActivity.new

      delete_activity.remover_name = remover.name
      delete_activity.item_id = item.id
      delete_activity.item_name = item.name

      return delete_activity
    end

    def what_happened
      db = Storage::Database.instance
      item = db.get_item_by_id(self.item_id)

      return "User #{self.actor_name} deleted item ##{self.item_id} #{self.item_name}"
    end
  end
end
