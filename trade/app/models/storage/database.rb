module Storage
  class Database

    def initialize
      @users = []
      @items = []
    end

    @@instance = Database.new

    private_class_method :new

    def self.instance
      return @@instance
    end

    def add_user(user)
      @users << user unless (@users.include?(user) or @users.index{|x| x.name == user.name} != nil)
    end

    def add_item(item)
      @items << item unless (@items.include?(item) or @items.index{|x| x.id == item.id} != nil)
    end

    def delete_item(item)
      fail "Cannot delete active items" if item.active?
      @items.delete(item)
    end

    def get_users
      return @users.dup
    end

    def get_items
      return @items.dup
    end

    def get_user_by_name(name)
      return @users.detect{|user| user.name == name}
    end

    def get_item_by_id(id)
      return @items.detect{|item| item.id == id}
    end

    def user_exists?(name)
      return !@@instance.get_user_by_name(name).nil?
    end
  end
end