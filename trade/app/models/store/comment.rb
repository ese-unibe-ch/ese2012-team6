# the comment class is responsible for the comment handling to an item
module Store
  class Comment
     attr_accessor :id, :description, :owner, :time_stamp

    @@last_id = 0
    @@comments = {}

    def initialize
      @@last_id += 1
      self.id = @@last_id
    end

    # creates a new comment to an item
    def self.new_comment(description, owner)
      comment = Comment.new
      comment.description = description
      comment.owner = owner
      comment.time_stamp = Time.now.asctime
      fail if @@comments.has_key?(comment.id)
      @@comments[comment.id] = comment
      return comment
    end

    # returns a chosen comment by its id
    def self.by_id(id)
      return @@comments[id]
    end

    # deletes a comment
    def delete
      @@comments.delete(self.id)
    end

    # handles smileys and the format of a comment
    def format_description
      formatted_desc = description.gsub(':)', '![alternative text](/images/smileys/smile.gif)').gsub(':D', '![alternative text](/images/smileys/laugh.gif)').
          gsub(':(', '![alternative text](/images/smileys/disappointed.gif)').gsub(':O', '![alternative text](/images/smileys/shocked.gif)').
          gsub(":,(", '![alternative text](/images/smileys/sad.gif)').gsub(':/', '![alternative text](/images/smileys/double_minded.gif)').
          gsub('8)', '![alternative text](/images/smileys/cool.gif)').gsub(':crazy:', '![alternative text](/images/smileys/crazy.gif)').
          gsub(':yeah:', '![alternative text](/images/smileys/yeah.gif)')
      return formatted_desc
    end
  end
end