require 'rbtree'
require_relative '../store/system_user'

# organization class inherits the super class system_user
# is responsible for handling with organizations
module Store
  class Organization < SystemUser
    attr_accessor :members, :admins

    @@organizations = RBTree.new
    @@name_id_rel = {}

    def initialize
      super
      self.members = []
      self.admins = []
    end

    # deletes all organizations in the system
    def self.clear_all
      @@organizations.clear
      @@name_id_rel.clear
    end

    # creates a new organization with certain options
    def self.named(name, options = {})
      organization = Organization.new
      organization.name = name
      organization.description = options[:description] || ""
      organization.add_admin(options[:admin]) if options[:admin]
      organization.add_member(options[:admin]) if options[:admin]
      organization.credits = options[:credits] if options[:credits]
      return organization
    end

    # fetches the organization object by its name or id
    def self.fetch_by(args = {})
      return  @@organizations[args[:id]] unless args[:id].nil?
      return  @@organizations[@@name_id_rel[args[:name]]] unless (args[:name].nil? || @@name_id_rel[args[:name]].nil?)

      return nil
    end

    # returns true if an organization object exists with the id or name
    def self.exists?(args = {})
      return @@organizations .has_key?(args[:id]) unless args[:id].nil?
      return @@name_id_rel.has_key?(args[:name])
    end

    # returns all saved organizations
    def self.all
      return  @@organizations.values.dup
    end

    # adds a member to an organization
    def add_member(member)
      member.enter_organization(self)
      members.push(member)
    end

    # removes a member from an organization
    def remove_member(member)
      members.delete(member)
      member.leave_organization(self)
    end

    # adds an admin to the organization
    def add_admin(member)
      admins.push(member)
    end

    # removes the admin from the organization
    def remove_admin(member)
      admins.delete(member)
    end

    # returns always true if called with an organization object
    def is_organization?
      true
    end

    # saves the organization to the system
    def save
      fail if  @@organizations.has_key?(self.id)
      @@organizations[self.id] = self
      @@name_id_rel[self.name] = self.id
      fail unless  @@organizations .has_key?(self.id)
    end

    # deletes the organization from the system
    def delete
      fail unless @@organizations .has_key?(self.id)
      @@organizations.delete(self.id)
      @@name_id_rel.delete(self.name)
      fail if @@organizations .has_key?(self.id)
    end

    # sends a certain amount of money from the organization to an admin
    def send_money_to(admin, amount)
      return false unless self.has_admin?(admin)
      super(admin, amount)
    end

    # determine whether a user is a member of this organization
    def has_member?(user)
      fail if user.nil?
      return self.members.include?(user)
    end

    # determine whether a user is an admin of this organization
    def has_admin?(user)
      fail if user.nil?
      return self.admins.include?(user)
    end
  end
end

