module Analytics
  module ActivityType
    if not defined? ITEM_BUY
      ITEM_BUY = "ItemBuy"
      ITEM_EDIT = "ItemEdit"
      ITEM_ADD = "ItemAdd"
      ITEM_STATUS_CHANGE = "ItemStatusChange"
      ITEM_DELETE = "ItemDelete"
      USER_LOGIN = "UserLogin"
      USER_LOGOUT = "UserLogout"
      NONE = "None"
    end
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

    def what_happened?
      return "Nothing"
    end
  end

  class ItemActivity < Activity
    attr_accessor :actor_name, :item_id, :item_name

    def initialize
      super
      self.actor_name = ""
      self.item_name = ""
      self.item_id = -1
    end

    def what_happened
      return "Nothing"
    end
  end

  class UserActivity < Activity
    attr_accessor :user_name

    def initialize
      super
      self.user_name = ""
    end

    def what_happened
      return "Nothing"
    end
  end

  class ItemBuyActivity < ItemActivity
    attr_accessor :price, :success

    def initialize
      super
      self.type = ActivityType::ITEM_BUY
      self.price = -1
      self.success = false
    end

    def self.with_buyer_item_price_success(buyer, item, success = true)
      buy_activity = ItemBuyActivity.new

      buy_activity.actor_name = buyer.name
      buy_activity.item_id = item.id
      buy_activity.item_name = item.name
      buy_activity.price = item.price
      buy_activity.success = success

      return buy_activity
    end

    def what_happened
      if self.success
        return "User #{self.actor_name} bought item ##{self.item_id} #{self.item_name} for #{self.price}$"
      else
        return "User #{self.actor_name} tried to buy item ##{self.item_id} #{self.item_name} for #{self.price}$ but purchase failed"
      end
    end
  end

  class ItemEditActivity < ItemActivity
    attr_accessor :old_values, :new_values

    def initialize
      super
      self.type = ActivityType::ITEM_EDIT
      self.old_values = {}
      self.new_values = {}
    end

    def self.with_editor_item_old_new_vals(editor, item, old_vals, new_vals)
      edit_activity = ItemEditActivity.new

      edit_activity.actor_name = editor.name unless editor.nil?

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


  class ItemAddActivity < ItemActivity

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

  class ItemStatusChangeActivity < ItemActivity
    attr_accessor :new_status

    def initialize
      super
      self.type = ActivityType::ITEM_STATUS_CHANGE
      self.new_status = nil
    end

    def self.with_editor_item_status(editor, item, new_status)
      status_change_activity = ItemStatusChangeActivity.new

      status_change_activity.actor_name = editor.name unless editor.nil?

      status_change_activity.item_id = item.id
      status_change_activity.item_name = item.name
      status_change_activity.new_status = new_status

      return status_change_activity
    end

    def what_happened
      return "User #{self.actor_name} changed status of item ##{self.item_id} #{self.item_name} to #{self.new_status ? "active" : "inactive"}"
    end
  end

  class ItemDeleteActivity < ItemActivity
    def initialize
      super
      self.type = ActivityType::ITEM_DELETE
    end

    def self.with_remover_item(remover, item)
      delete_activity = ItemDeleteActivity.new

      delete_activity.actor_name = remover.name
      delete_activity.item_id = item.id
      delete_activity.item_name = item.name

      return delete_activity
    end

    def what_happened
      return "User #{self.actor_name} deleted item ##{self.item_id} #{self.item_name}"
    end
  end

  class UserLoginActivity < UserActivity
    def initialize
      super
      self.type = ActivityType::USER_LOGIN
    end

    def self.with_username(user_name)
      login_act = UserLoginActivity.new
      login_act.user_name = user_name
      return login_act
    end

    def what_happened
      return "User #{self.user_name} logged in"
    end
  end

  class UserLogoutActivity < UserActivity
    def initialize
      super
      self.type = ActivityType::USER_LOGOUT
    end

    def self.with_username(user_name)
      logout_act = UserLogoutActivity.new
      logout_act.user_name = user_name
      return logout_act
    end

    def what_happened
      return "User #{self.user_name} logged out"
    end
  end
end
