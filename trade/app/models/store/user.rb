require 'bcrypt'
require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/system_user'
require_relative '../security/password_generator'
require_relative '../security/mail_client'

# user class inherits the super class system_user
# is responsible for user's handling
module Store
  class User < SystemUser
    # up to now only using IDs for efficient sorted storing
    @@users_by_id = RBTree.new
    @@users_by_name = {}

    attr_accessor  :pwd_hash, :pwd_salt, :on_behalf_of, :organizations, :email

    def initialize
      super
      self.credits = 100
      self.pwd_hash = ""
      self.pwd_salt = ""
      self.email = ""
      self.on_behalf_of = self
      self.organizations = []
    end

    # creates a user object with typed attributes
    def self.named(name, options = {})
      user = User.new
      user.name = name

      user.pwd_salt = BCrypt::Engine.generate_salt
      user.pwd_hash = BCrypt::Engine.hash_secret(options[:password] || name, user.pwd_salt)

      user.description = options[:description] || ""
	    user.email = options[:email] || ""

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

    # log in the user
    def login
      Analytics::UserLoginActivity.with_username(name).log
    end

    # log out the user
    def logout
      Analytics::UserLogoutActivity.with_username(name).log
    end

    # sends a certain amount of money from the user to a certain organization
    def send_money_to(organization, amount)
      fail if organization.nil?
      fail unless self.is_member_of?(organization)
      super(organization, amount)
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

    # saves an user object to the system
    def save
      fail if @@users_by_id.has_key?(self.id)
      @@users_by_id[self.id] = self
      @@users_by_name[self.name] = self
    end

    # deletes an user object from the system
    def delete
      fail unless  @@users_by_id.has_key?(self.id)
      @@users_by_id.delete(self.id)
      @@users_by_name.delete(self.name)
    end

    # clears all users from system
    def self.clear_all
      @@users_by_id.clear
      @@users_by_name.clear
    end

    # fetches the user object by its name
    def self.by_name(name)
      return self.fetch_by(:name => name)
    end

    # fetches the user object by its id
    def self.by_id(id)
      return self.fetch_by(:id => id)
    end

    # returns the user object which matches with the id or name
    def self.fetch_by(args = {})
      return  @@users_by_id[args[:id]] unless args[:id].nil?
      return  @@users_by_name[args[:name]] unless args[:name].nil?
      return nil
    end

    # returns true if a user object exists with the id or name
    def self.exists?(args = {})
      return @@users_by_id.has_key?(args[:id]) unless args[:id].nil?
      return @@users_by_name.has_key?(args[:name])
    end

    # returns all users in the system
    def self.all
      return @@users_by_id.values.dup
    end

    def reset_password()
      new_password = Security::PasswordGenerator.generate_new_password()
      self.change_password(new_password)
      Security::MailClient.send_mail(self.email, new_password)
    end
  end
end
