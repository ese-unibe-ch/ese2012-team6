require 'bcrypt'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/trader'
require_relative '../helpers/security/password_generator'
require_relative '../helpers/security/mail_client'
require_relative '../store/suspender'

module Store
  # Models a user that can log into the system and perform actions on items. It is able to create organizations which
  # it can work on behalf of. A new User always gets the initial amount of 100 credits to start trading with other users
  # It also provides services concerning user credentials which it stores
  class User < Trader
    # up to now only using IDs for efficient sorted storing
    @@users = {}

    attr_accessor :pwd_hash, :pwd_salt, :on_behalf_of, :organizations, :email

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

      user
    end

    # returns whether the password matches the saved password
    def password_matches?(password)
      self.pwd_hash == BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    # change the password of the user
    def change_password(password)
      self.pwd_salt = BCrypt::Engine.generate_salt
      self.pwd_hash = BCrypt::Engine.hash_secret(password, self.pwd_salt)
    end

    # log in the user
    def login
      Analytics::UserLoginActivity.create(name).log
      self.state = :active
      Store::Suspender.release_suspension_of self
    end

    # log out the user
    def logout
      Analytics::UserLogoutActivity.create(name).log
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
      self.on_behalf_of.eql?(self)
    end

    # return whether user is working on behalf of a certain organization
    def working_on_behalf_of?(org)
      self.on_behalf_of.eql?(org)
    end

    # returns whether user is a member of an organization
    def is_member_of?(organization)
      organization.has_member?(self)
    end

    # returns whether user is an admin of an organization
    def is_admin_of?(organization)
      organization.has_admin?(self)
    end

    # saves an user object to the system
    def save
      @@users[self.name] = self
    end

    # deletes an user object from the system
    def delete
      @@users.delete(self.name)
    end

    # reset a user's password and send email with new password if desired
    def reset_password(sendMail = true)
      new_password = Security::PasswordGenerator.generate_new_password()
      self.change_password(new_password)
      Security::MailClient.send_password_mail(self.email, new_password) if sendMail
      new_password
    end

    def suspend!
      self.state = :suspended
      self.items.each {|item| item.deactivate}
      Store::Suspender.suspend_user self
    end

    class << self
      # clears all users from system
      def clear_all
        @@users.clear
      end

      # fetches the user object by its name
      def by_name(name)
        @@users[name]
      end

      # returns true if a user object exists with the :id or :name
      def exists?(name)
        return @@users.has_key?(name)
      end

      # returns all users in the system
      def all
        all_users = @@users.values.sort { |a,b| a.id <=> b.id}
      end

      # returns all users in the system that are active
      def all_active
        all_users = self.all
        all_users.select {|a| a.state == :active}
      end

      def all_inactive
        all_users = self.all
        all_users.select {|a| a.state == :active}
      end
    end
  end
end
