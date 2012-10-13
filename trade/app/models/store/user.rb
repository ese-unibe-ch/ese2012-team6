require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../storage/database'

module Store
  class User
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

    def propose_item(name, price, description = "")
      item = Item.named_priced_with_owner(name, price, self)
      item.description = description

      self.items << item

      Storage::Database.instance.add_item(item)
      Analytics::ActivityLogger.log_activity(Analytics::ItemAddActivity.with_creator_item(self, item))

      return item
    end

    def get_active_items
      active_items = self.items.select {|i| i.active?}

      return active_items
    end

    def add_item(item)
      self.items << item
      item.owner = self
    end

    def remove_item(item)
      if self.items.include?(item)
        item.owner = nil
        self.items.delete(item)
      end
    end

    def delete_item(item)
      self.remove_item(item)
      Storage::Database.instance.delete_item(item)

      Analytics::ActivityLogger.log_activity(Analytics::ItemDeleteActivity.with_remover_item(self, item))
    end

    def buy_item(item)
      seller = item.owner

      if seller.nil?
        return false, "item_no_owner" #Item does not belong to anybody
      elsif self.credits < item.price
        return false, "not_enough_credits" #Buyer does not have enough credits
      elsif !item.active?
        return false, "buy_inactive_item" #Trying to buy inactive item
      elsif !seller.items.include?(item)
        return false, "seller_not_own_item" #Seller does not own item to buy
      end

      seller.remove_item(item)
      seller.credits += item.price

      item.owner = self
      item.set_inactive

      self.add_item(item)
      self.credits -= item.price
	    item.edit_time = Time.now
      Analytics::ActivityLogger.log_activity(Analytics::ItemBuyActivity.with_buyer_item_price(self, item))

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
  end
end
