require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'

class ItemTest < Test::Unit::TestCase
  include Store

  def test_item_name
    item_name = "TestItem"
    item = Item.named_priced_with_owner(item_name, 0, nil)
    assert_not_nil(item.name, "Item has no name")
    assert_equal(item_name, item.name)
  end

  def test_item_price
    item_price = 555
    item = Item.named_priced_with_owner("TestItem", item_price, nil)
    assert_equal(item_price, item.price)
  end

  def test_item_inactive_after_creation
    item = Item.new
    assert_equal(false, item.active?, "New items must be set inactive!")
  end

  def test_item_has_owner
    user = User.named("User")
    item = user.propose_item("TestItem", 100)
    assert_equal(user, item.owner)
  end

  def test_item_valid_price
    p1 = "20"
    p2 = "+20"
    p3 = "020"
    p4 = "-20"
    p5 = ""

    assert(Item.valid_price?(p1), "20 is a valid price")
    assert(Item.valid_price?(p2), "+20 is a valid price")
    assert(Item.valid_price?(p3), "020 is a valid price")
    assert(!Item.valid_price?(p4), "-20 is an invalid price")
    assert(!Item.valid_price?(p5), "empty is an invalid price")
  end

  def test_is_editable?
    item = Item.named_priced_with_owner("test",20,nil)
    item.activate
    assert_equal(false,item.editable?)
    item.deactivate
    assert_equal(true,item.editable?)
  end

  def test_change_status
    item = Item.named_priced_with_owner("TestItem", 0, nil)
    assert_equal(false, item.active?)

    item.update_status(true)

    assert_equal(true, item.active?)
  end

  def test_item_update
    item = Item.named_priced_with_owner("TestItem", 0, nil)
    item.update("NewName", 100, "NewDescription")

    assert_equal("NewName", item.name)
    assert_equal(100, item.price)
    assert_equal("NewDescription", item.description)
  end

  def test_item_save
    item = Item.named_priced_with_owner("TestItem", 0, nil)
    item.save
    assert_equal(item, Item.by_id(item.id))
  end

  def test_item_delete
    item = Item.named_priced_with_owner("TestItem", 0, nil)
    item.save
    assert_equal(item, Item.by_id(item.id))

    item.delete
    assert_equal(nil, Item.by_id(item.id))
  end

  def test_get_all_items
    Item.clear_all

    item1 = Item.named_priced_with_owner("TestItem1", 0, nil)
    item2 = Item.named_priced_with_owner("TestItem2", 0, nil)
    item3 = Item.named_priced_with_owner("TestItem3", 0, nil)

    item1.save
    item2.save
    item3.save

    all_items = Item.all

    [item1, item2, item3].each {
      |item|
      assert(item, all_items.include?(item))
    }

  end

  def test_is_editable_by_owner
    user = User.named("Hans")
    item = user.propose_item("TestItem", 100, "", false)
    assert_equal(true, item.editable_by?(user))
    item.activate
    assert_equal(false, item.editable_by?(user))
  end

  def test_is_editable_by_other
    user = User.named("Hans")
    other = User.named("Herbert")
    item = user.propose_item("TestItem", 100, "", false)
    assert_equal(true, item.editable_by?(user))
    item.activate
    assert_equal(false, item.editable_by?(other))
  end

  def test_activatable_by_owner
    user = User.named("Hans")
    item = user.propose_item("TestItem", 100, "", false)
    assert_equal(true, item.activatable_by?(user))
    item.activate
    assert_equal(true, item.activatable_by?(user))
  end

  def test_activatable_by_other
    user = User.named("Hans")
    other = User.named("Herbert")
    item = user.propose_item("TestItem", 100, "", false)
    assert_equal(true, item.activatable_by?(user))
    assert_equal(false, item.activatable_by?(other))
    item.activate
    assert_equal(true, item.activatable_by?(user))
    assert_equal(false, item.activatable_by?(other))
  end

  def test_add_comment
    comment = Comment.new_comment("newComment", nil)

    item = Item.named_priced_with_owner("NewItem", 100, nil)
    item.update_comments(comment)

    assert_equal(true, item.comments.include?(comment))
  end

  def test_delete_comment
    comment = Comment.new_comment("newComment", nil)

    item = Item.named_priced_with_owner("NewItem", 100, nil)
    item.comments << comment
    item.delete_comment(comment)
    assert_equal(false, item.comments.include?(comment))
    assert_equal(nil, Comment.by_id(comment))
  end
end