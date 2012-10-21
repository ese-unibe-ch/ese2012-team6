require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/system_user'

module Store
  class User < System_User
    @@users = {}

    attr_accessor  :pwd_hash, :pwd_salt, :on_behalf_of, :organizations

    def initialize
      self.name = ""
      self.credits = 100
      self.items = []
      self.pwd_hash = ""
      self.pwd_salt = ""
      self.description = ""
      self.open_item_page_time = Time.now
	    self.image_path = "/images/no_image.gif"
      self.on_behalf_of = self
      self.organizations = []
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

    # tell user to work on behalf of an organization
    def work_on_behalf_of(organization)
      self.on_behalf_of = organization
    end

    # become a member of an organization
    def enter_organization(organization)
      self.organizations << organization
    end

    # resign as a member of an organization
    def leave_organization(organization)
      self.organizations.delete organization
    end

    # return all organizations this user is a member of
    def get_organizations
      return self.organizations
    end
  end
end
