
module Store
  class Comment

     attr_accessor :id, :description, :owner, :time_stamp
    @@last_id = 0
    @@comments = {}

    def initialize
      @@last_id += 1
      self.id = @@last_id
    end

    def self.new_comment(description, owner, time_stamp)
      comment = Comment.new
      comment.description = description
      comment.owner = owner
      comment.time_stamp= time_stamp
      fail if @@comments.has_key?(comment.id)
      @@comments[comment.id] = comment
      return comment
    end

     def self.by_id(id)
       return @@comments[id]
     end
  end
end