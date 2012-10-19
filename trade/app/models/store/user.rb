require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/system_user'

module Store
  class User < System_User
    @@users = {}

    attr_accessor  :pwd_hash, :pwd_salt

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

    def password_matches?(password)
      return self.pwd_hash == BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    def change_password(password)
      self.pwd_salt = BCrypt::Engine.generate_salt
      self.pwd_hash = BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    def self.named_pwd_description(name, password, description)
      user = User.new
      user.name = name

      user.pwd_salt = BCrypt::Engine.generate_salt
      user.pwd_hash = BCrypt::Engine.hash_secret(password, user.pwd_salt)

      user.description = description

      return user
    end


    def login
      Analytics::UserLoginActivity.with_username(name).log
    end

    def logout
      Analytics::UserLogoutActivity.with_username(name).log
    end
  end
end
