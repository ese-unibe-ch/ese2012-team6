require 'bcrypt'
require 'rbtree'

require_relative '../analytics/activity_logger'
require_relative '../analytics/activity'
require_relative '../store/system_user'

module Store
  class User < SystemUser
    @@users = RBTree.new
    # map that maps unique usernames to IDs, for future use
    @@name_id_rel = {}

    attr_accessor  :pwd_hash, :pwd_salt, :on_behalf_of, :organizations

    def initialize
      super
      self.credits = 100
      self.pwd_hash = ""
      self.pwd_salt = ""
      self.email = ""
      self.on_behalf_of = self
      self.organizations = []
    end

    def self.by_name(name)
      return self.fetch_by(:name => name)
    end

    def self.by_id(id)
      return self.fetch_by(:id => id)
    end

    def self.fetch_by(args = {})
      return  @@users[args[:id]] unless args[:id].nil?
      return  @@users[@@name_id_rel[args[:name]]] unless (args[:name].nil? || @@name_id_rel[args[:name]].nil?)
      return nil
    end

    def self.exists?(args = {})
      return @@users .has_key?(args[:id]) unless args[:id].nil?
      return @@name_id_rel.has_key?(args[:name])
    end

    def self.all
      return @@users.values.dup
    end

    def save
      fail if @@users .has_key?(self.id)
      @@users[self.id] = self
      @@name_id_rel[self.name] = self.id
      fail unless @@users .has_key?(self.id)
    end

    def delete
      fail unless  @@users .has_key?(self.id)
      @@users .delete(self.id)
      @@name_id_rel.delete(self.name)
      fail if @@users .has_key?(self.id)
    end

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

    def take_item_snapshot
      self.open_item_page_time = Time.now
    end
  end
end
