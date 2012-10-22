require_relative '../store/system_user'
module Store
  class Organization < System_User
    attr_accessor :members, :admins
    @@organizations = {}

    def initialize
      self.name = ""
      self.credits = 0
      self.items = []
      self.description = ""
      self.open_item_page_time = Time.now
      self.image_path = "/images/no_image.gif"
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

    def self.by_name(name)
      return  @@organizations[name]
    end

    def self.all
      return  @@organizations .values.dup
    end

    def self.exists?(name)
      return  @@organizations .has_key?(name)
    end

    def send_money(amount)
      fail unless amount >= 0
      self.credits += amount
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

