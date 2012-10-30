require 'rbtree'
require_relative '../store/system_user'

module Store
  # Organizations offer the ability for users to work on behalf of each other. They behave just like a normal user, but
  # do not have a login. An organization has users and admins and it keeps track of those
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
      organization
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
      self.members.include?(user)
    end

    # determine whether a user is an admin of this organization
    def has_admin?(user)
      fail if user.nil?
      self.admins.include?(user)
    end

    # saves the organization to the system
    def save
      fail if @@organizations_by_id.has_key?(self.id)
      @@organizations_by_id[self.id] = self
      @@organizations_by_name[self.name] = self
    end

    # deletes the organization from the system
    def delete
      fail unless @@organizations_by_id.has_key?(self.id)
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
        return @@organizations_by_id[args[:id]] unless args[:id].nil?
        return @@organizations_by_name[args[:name]] unless args[:name].nil?
        nil
      end

      # returns true if an organization object exists with the id or name
      def exists?(args = {})
        return @@organizations_by_id.has_key?(args[:id]) unless args[:id].nil?
        @@organizations_by_name.has_key?(args[:name])
      end

      # returns all saved organizations
      def all
        @@organizations_by_id.values.dup
      end
    end
  end
end

