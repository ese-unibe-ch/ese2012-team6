
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

    def format_description
      formatted_desc = description.gsub(':)', '![alternative text](public/images/smile.gif)').gsub(':D', '![alternative text](public/images/laugh.gif)').
          gsub(':(', '![alternative text](public/images/disappointed.gif)').gsub(':O', '![alternative text](public/images/shocked.gif)').
          gsub(":'(", '![alternative text](public/images/sad.gif)').gsub(':/', '![alternative text](public/images/double_minded.gif)').
          gsub('8)', '![alternative text](public/images/cool.gif)').gsub(':crazy:', '![alternative text](public/images/crazy.gif)').
          gsub(':yeah:', '![alternative text](public/images/yeah.gif)')
      return formatted_desc

    end

  end
end