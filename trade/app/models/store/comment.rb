require 'json'
require 'orderedhash'

module Store
  # A simple data container that stores information about when the comment was created, what text is assigned to it and
  # the author of the comment
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
      @@comments[comment.id] = comment
      comment
    end

    # returns a chosen comment by its id
    def self.by_id(id)
      @@comments[id]
    end

    # deletes a comment
    def delete
      @@comments.delete(self.id)
    end

    # handles smileys and the format of a comment
    def get_formatted_description
      description.gsub(':)', '![alternative text](/images/smileys/smile.gif)').gsub(':D', '![alternative text](/images/smileys/laugh.gif)').
          gsub(':(', '![alternative text](/images/smileys/disappointed.gif)').gsub(':O', '![alternative text](/images/smileys/shocked.gif)').
          gsub(":,(", '![alternative text](/images/smileys/sad.gif)').gsub(':/', '![alternative text](/images/smileys/double_minded.gif)').
          gsub('8)', '![alternative text](/images/smileys/cool.gif)').gsub(':crazy:', '![alternative text](/images/smileys/crazy.gif)').
          gsub(':yeah:', '![alternative text](/images/smileys/yeah.gif)')
    end

    def to_json(*opt)
      hash = OrderedHash.new

      hash[:id] = self.id
      hash[:author] = self.owner.name
      hash[:text] = self.description
      hash[:posted_on] = self.time_stamp

      hash.to_json(*opt)
    end
  end
end