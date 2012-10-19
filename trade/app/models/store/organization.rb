require_relative '../store/system_user'
module Store
  class Organization < System_User
    attr_accessor :name, :credits, :items,  :description, :open_item_page_time, :image_path, :organization_members, :organization_admin

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
      organization_members.push(member)
    end

    def self.named(name)
      organization = Organization.new
      organization.name = name
    end

    def remove_member(member)
      organization_members.pop(member)
    end

    def add_admin(member)
    organization_admin.push(member)

    end

    def is_organization?
      true
    end




  end
end

