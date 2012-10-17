require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'

module Store
  class User
    @@users = {}

    attr_accessor :name, :credits, :items, :pwd_hash, :pwd_salt, :description, :open_item_page_time, :image_path

    def initialize
      self.name = ""
      self.credits = 100
      self.items = []
      self.pwd_hash = ""
      self.pwd_salt = ""
      self.description = ""
      self.open_item_page_time = Time.now
	    self.image_path = "/images/no_image.gif"
    end

    def name=(name)
      @name = Security::StringChecker.destroy_script(name)
    end

    def save
      @@users[self.name] = self
    end

    def delete
      @@users.delete(self.name)
    end

    def self.by_name(name)
      return @@users[name]
    end

    def self.all
      return @@users.values.dup
    end

    def self.exists?(name)
      return @@users.has_key?(name)
    end

    def self.named(name)
      user = User.new
      user.name = name

      user.pwd_salt = BCrypt::Engine.generate_salt
      user.pwd_hash = BCrypt::Engine.hash_secret(name, user.pwd_salt)

      return user
    end

    def self.named_with_pwd(name, password)
      user = User.new
      user.name = name

      user.pwd_salt = BCrypt::Engine.generate_salt
      user.pwd_hash = BCrypt::Engine.hash_secret(password, user.pwd_salt)

      return user
    end

    def self.named_pwd_description(name, password, description)
      user = User.new
      user.name = name

      user.pwd_salt = BCrypt::Engine.generate_salt
      user.pwd_hash = BCrypt::Engine.hash_secret(password, user.pwd_salt)

      user.description = description

      return user
    end

    def password_matches?(password)
      return self.pwd_hash == BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    def change_password(password)
      self.pwd_salt = BCrypt::Engine.generate_salt
      self.pwd_hash = BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    def propose_item(name, price, description = "", log = true)
      item = Item.named_priced_with_owner(name, price, self)
      item.description = description

      item.save
      self.attach_item(item)

      Analytics::ItemAddActivity.with_creator_item(self, item).log if log

      return item
    end

    def get_active_items
      active_items = self.items.select {|i| i.active?}

      return active_items
    end

    def attach_item(item)
      self.items << item
      item.owner = self
    end

    def release_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    def delete_item(item_id, log = true)
      item = Store::Item.by_id(item_id)

      self.release_item(item)
      item.delete

      Analytics::ItemDeleteActivity.with_remover_item(self, item).log if log
    end

    def buy_item(item, log = true)
      seller = item.owner

      if seller.nil?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < item.price
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item, false).log if log
        return false, "seller_not_own_item" #Seller does not own item to buy
      end

      seller.release_item(item)
      seller.credits += item.price

      item.deactivate

      self.attach_item(item)
      self.credits -= item.price

	    item.notify_change

      Analytics::ItemBuyActivity.with_buyer_item_price_success(self, item).log if log

      return true, "Transaction successful"
    end

    def can_edit?(item)
      return (item.owner.eql?(self) and item.editable?)
    end

    alias :can_delete? :can_edit?

    def can_buy?(item)
      return (not item.owner.eql?(self) and item.active?)
    end

    def can_activate?(item)
      return item.owner.eql?(self)
    end

    def to_s
      return "#{self.name}, #{self.credits}"
    end

    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
    end

    def login
      Analytics::UserLoginActivity.with_username(name).log
    end

    def logout
      Analytics::UserLogoutActivity.with_username(name).log
    end
  end
end
