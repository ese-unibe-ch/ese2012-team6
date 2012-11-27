require_relative '../store/trader'

module Store
  # Organizations offer the ability for users to work on behalf of each other. They behave just like a normal user, but
  # do not have a login. An organization has members and admins which it keeps track of
  class Organization < Trader
    attr_accessor :members, :admins

    @@organizations = {}

    def initialize
      super
      self.members = []
      self.admins = []
    end

    # creates a new organization with certain options (:admin, :description, :credits)
    # If :admin is specified, it will be added as an admin and a member of the organization
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

    # determine whether a user is a member of this organization
    def has_member?(user)
      if user.active == false
        return false
      end
      self.members.include?(user)
    end

    # determine whether a user is an admin of this organization
    def has_admin?(user)
      self.admins.include?(user)
    end

    # saves the organization to the system
    def save
      @@organizations[self.name] = self
    end

    # deletes the organization from the system
    def delete
      @@organizations.delete(self.name)
    end

    def email
      emails = []
      self.members.each {|member|
        emails.push member.email
      }
      emails
    end

    # class methods
    class << self
      # deletes all organizations in the system
      def clear_all
        @@organizations.clear
      end

      # returns true if an organization object exists with the :id or :name specified
      def exists?(name)
        @@organizations.has_key?(name)
      end

      # fetches the user object by its name
      def by_name(name)
        @@organizations[name]
      end

      # returns all saved organizations
      def all
        @@organizations.values.sort { |a,b| a.id <=> b.id}
      end
    end
  end
end

