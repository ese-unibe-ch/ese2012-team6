require 'rbtree'
require_relative '../store/system_user'

# organization class inherits the super class system_user
# is responsible for handling with organizations
module Store
  class Organization < SystemUser
    attr_accessor :members, :admins

    # up to now only using IDs for efficient sorted storing
    @@organizations_by_id = RBTree.new
    @@organizations_by_name = {}

    def initialize
      super
      self.members = []
      self.admins = []
    end

    # creates a new organization with certain options (:admin, :description, :credits)
    def self.named(name, options = {})
      organization = Organization.new
      organization.name = name
      organization.description = options[:description] || ""
      organization.add_admin(options[:admin]) if options[:admin]
      organization.add_member(options[:admin]) if options[:admin]
      organization.credits = options[:credits] if options[:credits]
      return organization
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

    # saves the organization to the system
    def save
      fail if @@organizations_by_id.has_key?(self.id)
      @@organizations_by_id[self.id] = self
      @@organizations_by_name[self.name] = self
    end

    # deletes the organization from the system
    def delete
      fail unless @@organizations_by_id .has_key?(self.id)
      @@organizations_by_id.delete(self.id)
      @@organizations_by_name.delete(self.name)
    end

    # class methods
    class << self
      # deletes all organizations in the system
      def clear_all
        @@organizations_by_name.clear
        @@organizations_by_id.clear
      end

      # fetches the organization object by its name or id
      def fetch_by(args = {})
        return  @@organizations_by_id[args[:id]] unless args[:id].nil?
        return  @@organizations_by_name[args[:name]] unless args[:name].nil?

        return nil
      end

      # returns true if an organization object exists with the id or name
      def exists?(args = {})
        return @@organizations_by_id.has_key?(args[:id]) unless args[:id].nil?
        return @@organizations_by_name.has_key?(args[:name])
      end

      # returns all saved organizations
      def all
        return @@organizations_by_id.values.dup
      end
    end
  end
end

