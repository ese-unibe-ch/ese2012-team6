module Storage

  # Singleton object for basic data storage and provides API to get and change said data
  class Database

    def initialize
      @users = []
      @items = []
      @activities = []
    end

    @@instance = Database.new

    #private_class_method :new

    # Get the database instance
    def self.instance
      return @@instance
    end

    # add user to database
    def add_user(user)
      @users << user unless (@users.include?(user) or @users.index{|x| x.name == user.name} != nil)
    end

    # add item to database
    def add_item(item)
      @items << item unless (@items.include?(item) or @items.index{|x| x.id == item.id} != nil)
    end

    # delete item from database
    def delete_item(item)
      fail "Cannot delete active items" if item.active?
      @items.delete(item)
    end

    # get a copy of the list of all users in the database
    def get_users
      return @users.dup
    end

    # get a copy of the list of all items in the database
    def get_items
      return @items.dup
    end

    # retrieve a user object by name
    def get_user_by_name(name)
      return @users.detect{|user| user.name == name}
    end

    # retrieve an item object by id
    def get_item_by_id(id)
      return @items.detect{|item| item.id == id}
    end

    # check whether username already exists in database
    def user_exists?(name)
      return !@@instance.get_user_by_name(name).nil?
    end

    def add_activity(activity)
      @activities << activity
    end

    def get_all_activities
      return @activities.dup
    end

    def get_activity_by_id(id)
      return @activities.detect{|act| act.id == id}
    end
  end
end