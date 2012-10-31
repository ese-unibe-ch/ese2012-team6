require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/comment'
require_relative '../app/models/store/user'

class CommentTest < Test::Unit::TestCase

  def test_create_comment
    user = Store::User.named("John")
    comment = Store::Comment.new_comment("hallo", user)
    assert_not_nil(comment.description, "Comment has no description")
    assert(comment.description == "hallo")
    assert_not_nil(comment.owner, "Comment has no owner")
    assert(comment.owner == user)
    assert_not_nil(comment.time_stamp, "Comment has no time_stamp")
  end

  def test_format_description
    user = Store::User.named("John")
    description = ":)"
    comment = Store::Comment.new_comment(description, user)
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

  def test_delete_comment
    comment = Store::Comment.new_comment("hallo", nil)
    comment_id = comment.id
    comment.delete
    assert_equal(nil, Store::Comment.by_id(comment_id))
  end
end