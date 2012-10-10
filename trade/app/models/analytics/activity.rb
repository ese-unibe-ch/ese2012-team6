module Analytics
  module ActivityType
    ITEM_BUY = "ItemBuy"
    ITEM_EDIT = "ItemEdit"
    ITEM_ADD = "ItemAdd"
    ITEM_STATUS_CHANGE = "ItemStatusChange"
    NONE = "None"
  end

  class Activity
    attr_accessor :id, :type, :timestamp
    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
      self.type = ActivityType::NONE
      self.timestamp = Time.now.getutc
    end

    def what_happened
      return "Nothing"
    end

  end

  class BuyActivity < Activity
    attr_accessor :buyer, :item_id, :price

    def initialize
      super
      self.type = ActivityType::ITEM_BUY
      self.buyer = nil
      self.item_id = -1
      self.price = -1
    end

    def self.with_buyer_item_price(buyer, item_id, price)
      buy_activity = BuyActivity.new

      buy_activity.buyer = buyer
      buy_activity.item_id = item_id
      buy_activity.price = price

      return buy_activity
    end
  end

  class ItemEditActivity < Activity
    attr_accessor :editor, :item_id, :old_values, :new_values

    def initialize
      super
      self.type = ActivityType::ITEM_EDIT
      self.editor = nil
      self.item_id = -1
      self.old_values = []
      self.new_values = []
    end

    def self.with_editor_item_old_new_vals(editor, item_id, old_vals, new_vals)
      edit_activity = ItemEditActivity.new

      edit_activity.editor = editor
      edit_activity.item_id = item_id
      edit_activity.old_values = old_vals
      edit_activity.new_values = new_vals

      return edit_activity
    end
  end


  class ItemAddActivity < Activity
    attr_accessor :creator, :item_id

    def initialize
      super
      self.type = ActivityType::ITEM_ADD
      self.creator = nil
      self.item_id = -1
    end

    def self.with_creator_item(creator, item_id)
      add_activity = ItemAddActivity.new

      add_activity.creator = creator
      add_activity.item_id = item_id
     
      return add_activity
    end
  end

  class ItemStatusChangeActivity < Activity
    attr_accessor :editor, :item_id, :new_status

    def initialize
      super
      self.type = ActivityType::ITEM_STATUS_CHANGE
      self.editor = nil
      self.item_id = -1
      self.new_status = nil
    end

    def self.with_editor_item_status(editor, item_id, new_status)
      status_change_activity = ItemStatusChangeActivity.new

      status_change_activity.editor = editor
      status_change_activity.item_id = item_id
      status_change_activity.new_status = new_status

      return status_change_activity
    end
  end
end
