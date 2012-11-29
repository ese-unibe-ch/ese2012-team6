module Analytics
  # Provides the skeleton for all derived activities, stores information about when it was created or what type this activity is made of
  class Activity
    attr_accessor :id, :type, :timestamp

    def initialize
      self.id = -1
      self.type = :NONE
      self.timestamp = Time.now
    end

    # Returns a string stating what this activity has stored
    def what_happened?
      "Nothing"
    end

    # Saves this activity to a location using the ActivityLogger class
    def log
      ActivityLogger.log(self)
    end
  end

  # Activity that provides the skeleton for all activities concerning items, and actions on or from items
  class ItemActivity < Activity
    attr_accessor :actor_name, :item_id, :item_name

    def initialize
      super
      self.actor_name = ""
      self.item_name = ""
      self.item_id = -1
    end

    def what_happened
      "Nothing"
    end
  end

  # Activity that provides the skeleton for all activities concerning users, and actions on or from users
  class UserActivity < Activity
    attr_accessor :user_name

    def initialize
      super
      self.user_name = ""
    end

    def what_happened
      "Nothing"
    end
  end

  # Activity that stores information about buy actions
  class ItemBuyActivity < ItemActivity
    attr_accessor :price, :quantity, :success

    def initialize
      super
      self.type = :ITEM_BUY
      self.price = -1
      self.quantity = -1
      self.success = false
    end

    # creates a new ItemBuyActivity, with a buyer, item, and whether the buy process was successful
    def self.create(buyer, item, quantity = 1, success = true)
      buy_activity = ItemBuyActivity.new

      buy_activity.actor_name = buyer.name
      buy_activity.item_id = item.id
      buy_activity.item_name = item.name
      buy_activity.price = item.price
      buy_activity.success = success
      buy_activity.quantity = quantity

      buy_activity
    end

    def what_happened
      return "User #{self.actor_name} bought #{self.quantity} item ##{self.item_id} #{self.item_name} for #{self.price * self.quantity}$" if self.success
      "User #{self.actor_name} tried to buy #{self.quantity} item ##{self.item_id} #{self.item_name} for #{self.price}$ but purchase failed"
    end
  end

  # Activity that stores information about item edit actions
  class ItemEditActivity < ItemActivity
    attr_accessor :old_values, :new_values

    def initialize
      super
      self.type = :ITEM_EDIT
      self.old_values = {}
      self.new_values = {}
    end

    # creates a new ItemEditActivity, with an editor, item, and both old and new edit values
    def self.create(editor, item, old_vals, new_vals)
      edit_activity = ItemEditActivity.new

      edit_activity.actor_name = editor.name unless editor.nil?

      edit_activity.item_id = item.id
      edit_activity.item_name = item.name
      edit_activity.old_values = old_vals
      edit_activity.new_values = new_vals

      edit_activity
    end

    def what_happened
      "User #{self.actor_name} edited item ##{self.item_id} #{self.item_name}"
    end
  end

  # Activity that stores information about Item creation
  class ItemAddActivity < ItemActivity

    def initialize
      super
      self.type = :ITEM_ADD
    end

    # creates a new ItemAddActivity with the creator of the created item and the item itself
    def self.create(creator, item)
      add_activity = ItemAddActivity.new

      add_activity.actor_name = creator.name
      add_activity.item_id = item.id
      add_activity.item_name = item.name

      add_activity
    end

    def what_happened
      "User #{self.actor_name} added item ##{self.item_id} #{self.item_name}"
    end
  end

  # Activity that stores information about the status change of an item
  class ItemStatusChangeActivity < ItemActivity
    attr_accessor :new_status

    def initialize
      super
      self.type = :ITEM_STATUS_CHANGE
      self.new_status = nil
    end

    # Creates new ItemStatusChangeActivity with the user that initiated the status change, the item itself and the new status of the item
    def self.create(editor, item, new_status)
      status_change_activity = ItemStatusChangeActivity.new

      status_change_activity.actor_name = editor.name unless editor.nil?

      status_change_activity.item_id = item.id
      status_change_activity.item_name = item.name
      status_change_activity.new_status = new_status

      status_change_activity
    end

    def what_happened
      "User #{self.actor_name} changed status of item ##{self.item_id} #{self.item_name} to #{self.new_status ? "active" : "inactive"}"
    end
  end

  # Activity that stores information about item deletion
  class ItemDeleteActivity < ItemActivity
    def initialize
      super
      self.type = :ITEM_DELETE
    end

    # Creates new ItemDeleteActivity with the remover of the item, and the item itself
    def self.create(remover, item)
      delete_activity = ItemDeleteActivity.new

      delete_activity.actor_name = remover.name
      delete_activity.item_id = item.id
      delete_activity.item_name = item.name

      delete_activity
    end

    def what_happened
      "User #{self.actor_name} deleted item ##{self.item_id} #{self.item_name}"
    end
  end

  # Activity that stores information about user login
  class UserLoginActivity < UserActivity
    def initialize
      super
      self.type = :USER_LOGIN
    end

    # Creates new UserLoginActivity with the newly logged in user
    def self.create(user_name)
      login_act = UserLoginActivity.new
      login_act.user_name = user_name
      login_act
    end

    def what_happened
      "User #{self.user_name} logged in"
    end
  end

  # Activity that stores information about user logout
  class UserLogoutActivity < UserActivity
    def initialize
      super
      self.type = :USER_LOGOUT
    end

    # Creates new UserLoginActivity with the newly logged out user
    def self.create(user_name)
      logout_act = UserLogoutActivity.new
      logout_act.user_name = user_name
      logout_act
    end

    def what_happened
      "User #{self.user_name} logged out"
    end
  end
end
