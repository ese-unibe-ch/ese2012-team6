
module Store
  class Comment

     attr_accessor :id, :description, :owner, :time_stamp

    @@last_id = 0

    def initialize
      @@last_id += 1
      self.id = @@last_id
    end

    def self.new_comment(description, owner, time_stamp)
      comment = Comment.new
      comment.description = description
      comment.owner = owner
      comment.time_stamp= time_stamp
      return comment
    end
  end
end