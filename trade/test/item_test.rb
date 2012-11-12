require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'

class ItemTest < Test::Unit::TestCase
  include Store

  def before
    Item.clear_all
  end

  def test_item_name
    item_name = "TestItem"
    item = Item.named_priced_with_owner_fixed(item_name, 0, nil)
    assert item.isFixed?
    assert !item.isAuction?
    assert_not_nil(item.name, "Item has no name")
    assert_equal(item_name, item.name)
  end

  def test_item_price
    item_price = 555
    item = Item.named_priced_with_owner_fixed("TestItem", item_price, nil)
    assert_equal(item_price, item.price)
  end

  def test_item_inactive_after_creation
    item = Item.new
    assert_equal(false, item.active?, "New items must be set inactive!")
  end

  def test_item_has_owner
    user = User.named("User")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil)
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
    item = Item.named_priced_with_owner_fixed("test",20,nil)
    item.activate
    assert_equal(false,item.editable?)
    item.deactivate
    assert_equal(true,item.editable?)

    item = Item.named_priced_with_owner_auction("myItem", 10, nil, 2, 0, description = "test")
    item.activate
    assert !item.editable?
    item.deactivate
    assert item.editable?
  end

  def test_change_status
    item = Item.named_priced_with_owner_fixed("TestItem", 0, nil)
    assert_equal(false, item.active?)

    item.update_status(true)

    assert_equal(true, item.active?)
  end

  def test_item_update
    item = Item.named_priced_with_owner_fixed("TestItem", 0, nil)
    item.update("NewName", 100, "NewDescription", "fixed", nil, nil)

    assert_equal("NewName", item.name)
    assert_equal(100, item.price)
    assert_equal("NewDescription", item.description)
  end

  def test_item_save
    item = Item.named_priced_with_owner_fixed("TestItem", 0, nil)
    item.save
    assert_equal(item, Item.by_id(item.id))
  end

  def test_item_delete
    item = Item.named_priced_with_owner_fixed("TestItem", 0, nil)
    item.save
    assert_equal(item, Item.by_id(item.id))

    item.delete
    assert_equal(nil, Item.by_id(item.id))
  end

  def test_get_all_items
    Item.clear_all

    item1 = Item.named_priced_with_owner_fixed("TestItem1", 0, nil)
    item2 = Item.named_priced_with_owner_fixed("TestItem2", 0, nil)
    item3 = Item.named_priced_with_owner_fixed("TestItem3", 0, nil)

    item1.save
    item2.save
    item3.save

    assert_equal([item1, item2, item3], Item.all)
  end

  def test_is_editable_by_owner
    user = User.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, item.editable_by?(user))
    item.activate
    assert_equal(false, item.editable_by?(user))
  end

  def test_is_editable_by_other
    user = User.named("Hans")
    other = User.named("Herbert")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, item.editable_by?(user))
    item.activate
    assert_equal(false, item.editable_by?(other))
  end

  def test_activatable_by_owner
    user = User.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, item.activatable_by?(user))
    item.activate
    assert_equal(true, item.activatable_by?(user))
  end

  def test_activatable_by_other
    user = User.named("Hans")
    other = User.named("Herbert")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, item.activatable_by?(user))
    assert_equal(false, item.activatable_by?(other))
    item.activate
    assert_equal(true, item.activatable_by?(user))
    assert_equal(false, item.activatable_by?(other))
  end

  def test_add_comment
    comment = Comment.new_comment("newComment", nil)

    item = Item.named_priced_with_owner_fixed("NewItem", 100, nil)
    item.update_comments(comment)

    assert_equal(true, item.comments.include?(comment))
  end

  def test_delete_comment
    comment = Comment.new_comment("newComment", nil)

    item = Item.named_priced_with_owner_fixed("NewItem", 100, nil)
    item.comments << comment
    item.delete_comment(comment)
    assert_equal(false, item.comments.include?(comment))
    assert_equal(nil, Comment.by_id(comment))
  end
  
  def test_time_delta
    item = Item.named_priced_with_owner_auction("myItem", 10, nil, 2, DateTime.now + 1105, description = "test") # more than two hours valid
    assert item.time_delta_string == "3 years"

    item.end_time = DateTime.now + 365+31+31+10
    assert item.time_delta_string == "One year, 2 months"

    item.end_time = DateTime.now + 370
    assert item.time_delta_string == "One year"

    item.end_time = DateTime.now + 30+30+30+10
    assert item.time_delta_string == "3 months"

    item.end_time = DateTime.now + 30+10 +(1.0/24)  # add one hour to prevent rounding errors
    assert item.time_delta_string == "One month, 10 days"

    item.end_time = DateTime.now + 30
    assert item.time_delta_string == "One month"

    item.end_time = DateTime.now + 5  +(1.0/24)  # add one hour to prevent rounding errors
    assert item.time_delta_string == "5 days"

    item.end_time = DateTime.now + 1.51 +(2.0/(24*60)) # add 2 minutes to prevent rounding errors
    assert item.time_delta_string == "One day, 12 hours"

    item.end_time = DateTime.now + 1 + (1.0/(24*60))
    assert item.time_delta_string == "One day"

    item.end_time = DateTime.now + 2.0/24 + (5.0/(24*60))
    assert item.time_delta_string == "2 hours"

    item.end_time = DateTime.now + (52.0/(24*60))
    assert item.time_delta_string == "One hour"

    item.end_time = DateTime.now + 2.0/(24*60) + (2.0/(24*60*60))
    assert item.time_delta_string == "2 minutes"

    item.end_time = DateTime.now + (30.0/(24*60*60)) + (1.0/(24*60*60*10))
    assert item.time_delta_string == "30 seconds"

    item.end_time = DateTime.now - 30
    assert item.time_delta_string == "Auction is over since: One month ago"

    item.end_time = DateTime.now - 30-10 -(1.0/24)  # add one hour to prevent rounding errors
    assert item.time_delta_string == "Auction is over since: One month, 10 days ago"
  end
end