require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/comment'
require_relative '../app/models/store/user'

class Comment_Test < Test::Unit::TestCase

  def test_create_comment
    user = Store::User.named("John")
    comment = Store::Comment.new_comment("hallo", user, 3000)
    assert_not_nil(comment.description, "Comment has no description")
    assert(comment.description == "hallo")
    assert_not_nil(comment.owner, "Comment has no owner")
    assert(comment.owner == user)
    assert_not_nil(comment.time_stamp, "Comment has no time_stamp")
    assert(comment.time_stamp == 3000)
  end

  def test_format_description
    user = Store::User.named("John")
    description = ":)"
    comment = Store::Comment.new_comment(description, user, 3000)
    assert_equal(comment.format_description, "![alternative text](/images/smileys/smile.gif)")
    comment.description = ":D"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/laugh.gif)")
    comment.description = ":("
    assert_equal(comment.format_description, "![alternative text](/images/smileys/disappointed.gif)")
    comment.description = ":,("
    assert_equal(comment.format_description, "![alternative text](/images/smileys/sad.gif)")
    comment.description = ":/"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/double_minded.gif)")
    comment.description = "8)"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/cool.gif)")
    comment.description = ":O"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/shocked.gif)")
    comment.description = ":crazy:"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/crazy.gif)")
    comment.description = ":yeah:"
    assert_equal(comment.format_description, "![alternative text](/images/smileys/yeah.gif)")
  end

end