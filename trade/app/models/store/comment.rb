
module Store
  class Comment

     attr_accesor :id, :description, :owner
    @@last_id

    def initialize
      @@last_id += 1
      self.id = @@last_id
    end

    def self.new_comment(description, owner)
      comment = Comment.new
      comment.description = description
      comment.owner = owner
      return comment
    end
  end
end