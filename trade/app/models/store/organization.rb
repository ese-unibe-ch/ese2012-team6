require 'rbtree'
require_relative '../store/system_user'

module Store
  class Organization < SystemUser
    attr_accessor :members, :admins
    @@organizations = RBTree.new

    def initialize
      super
      self.members =[]
      self.admins =[]
    end

    # @param [User] member
    def add_member(member)
      member.enter_organization(self)
      members.push(member)
    end

    def self.named(name)
      organization = Organization.new
      organization.name = name
      return organization
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
      fail if  @@organizations .has_key?(self.name)
      @@organizations[self.name] = self
      fail unless  @@organizations .has_key?(self.name)
    end

    def delete
      fail unless  @@organizations .has_key?(self.name)
      @@organizations .delete(self.name)
      fail if  @@organizations .has_key?(self.name)
    end

    def self.fetch_by(*args)
      fail unless (args[:name] || args[:id])
      return  @@organizations[args[:id]] unless args[:id].nil?
      return  @@organizations.detect{|org| org.name == args[:name]}
    end

    def self.exists?(*args)
      fail unless (args[:name] || args[:id])
      return @@organizations .has_key?(args[:id]) unless args[:id].nil?
      return @@organizations.each{|org| org.name == args[:name]}
    end

    def self.all
      return  @@organizations .values.dup
    end

    def send_money(amount)
      fail unless amount >= 0
      self.credits += amount
    end

    # sends a certain amount of money from the organization to an admin
    def send_money_to(admin, amount)
      fail if admin.nil?
      return false unless self.credits >= amount
      return false unless self.has_admin?(admin)

      self.credits -= amount
      admin.send_money(amount)

      fail if self.credits < 0

      return true
    end

    # determine whether a user is a member of this organization
    def has_member?(user)
      fail if user.nil?
      return self.members.include?(user)
    end
    
    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
    end

    # determine whether a user is an admin of this organization
    def has_admin?(user)
      fail if user.nil?
      return self.admins.include?(user)
    end
  end
end

