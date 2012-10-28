require 'rbtree'
require_relative '../store/system_user'

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

    def self.named(name, options = {})
      organization = Organization.new
      organization.name = name
      organization.description = options[:description] || ""
      organization.add_admin(options[:admin]) if options[:admin]
      organization.add_member(options[:admin]) if options[:admin]

      return organization
    end

    def self.fetch_by(args = {})
      return  @@organizations[args[:id]] unless args[:id].nil?
      return  @@organizations[@@name_id_rel[args[:name]]] unless (args[:name].nil? || @@name_id_rel[args[:name]].nil?)

      return nil
    end

    def self.exists?(args = {})
      return @@organizations .has_key?(args[:id]) unless args[:id].nil?
      return @@name_id_rel.has_key?(args[:name])
    end

    def self.all
      return  @@organizations.values.dup
    end

    # @param [User] member
    def add_member(member)
      member.enter_organization(self)
      members.push(member)
    end

    def remove_member(member)
      members.delete(member)
      member.leave_organization(self)
    end

    def add_admin(member)
      admins.push(member)
    end

    def remove_admin(member)
      admins.delete(member)
    end

    def is_organization?
      true
    end

    def save
      fail if  @@organizations.has_key?(self.id)
      @@organizations[self.id] = self
      @@name_id_rel[self.name] = self.id
      fail unless  @@organizations .has_key?(self.id)
    end

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

