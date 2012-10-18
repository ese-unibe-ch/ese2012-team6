
module Store
  class Organization < User
    attr_accessor :name, :credits, :items,  :description, :open_item_page_time, :image_path, :organization_members

    def initialize
      self.name = ""
      self.credits = 0
      self.items = []
      self.description = ""
      self.open_item_page_time = Time.now
      self.image_path = "/images/no_image.gif"
      self.organization_members =[]
    end



    def self.named(name)
      organization  = Organization.new
      organization.name = name

      return organization
    end

    # @param [User] member
    def add_member(member)
      organization_members.push(member)
    end

    def remove_member(member)
      organization_members.remove_instance_variable(member)
    end

  end
end

