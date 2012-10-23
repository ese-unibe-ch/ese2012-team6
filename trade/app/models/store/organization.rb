require_relative '../store/system_user'
module Store
  class Organization < System_User
    attr_accessor :organization_members, :organization_admin
    @@organizations = {}

    def initialize
      self.name = ""
      self.credits = 0
      self.items = []
      self.description = ""
      self.open_item_page_time = Time.now
      self.image_path = "/images/no_image.gif"
      self.organization_members =[]
      self.organization_admin =[]
    end

    # @param [User] member
    def add_member(member)
      member.enter_organization(self)
      organization_members.push(member)

    end

    def self.named(name)
      organization = Organization.new
      organization.name = name
      return organization
    end

    def remove_member(member)
      organization_members.delete(member)
      member.leave_organization(self)

    end

    def add_admin(member)
      organization_admin.push(member)
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

    def self.id_image_to_filename(id, path)
      "#{id}_#{path}"
    end

  end
end

