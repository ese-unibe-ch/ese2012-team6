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

    # returns whether the password matches the saved password
    def password_matches?(password)
      return self.pwd_hash == BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    # change the password of the user
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

    # log in the user
    def login
      Analytics::UserLoginActivity.with_username(name).log
    end
    # log out the user
    def logout
      Analytics::UserLogoutActivity.with_username(name).log
    end

    def send_money(amount)
      fail unless amount >= 0
      self.credits += amount
    end

    # sends a certain amount of money from the user to a certain organization
    def send_money_to(organization, amount)
      fail if organization.nil?
      return false unless self.credits >= amount

      self.credits -= amount
      organization.send_money(amount)

      fail if self.credits < 0

      return true
    end

    # tell user to work on behalf of an organization
    def work_on_behalf_of(organization)
      self.on_behalf_of = organization.nil? ? self : organization
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

    # return whether user is working on behalf of himself or not
    def working_as_self?
      return self.on_behalf_of.eql?(self)
    end

    # return whether user is working on behalf of a certain organization
    def working_on_behalf_of?(org)
      return self.on_behalf_of.eql?(org)
    end

    # returns whether user is a member of an organization
    def is_member_of?(organization)
      return organization.has_member?(self)
    end

    # returns whether user is an admin of an organization
    def is_admin_of?(organization)
      return organization.has_admin?(self)
    end
  end
end
