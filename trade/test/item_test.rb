require 'test/unit'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/security/string_checker'

class ItemTest < Test::Unit::TestCase
  def test_item_name
    item_name = "TestItem"
    item = Store::Item.named_priced_with_owner(item_name, 0, nil)
    assert_not_nil(item.name, "Item has no name")
    assert(item.name == item_name)
  end

  def test_item_price
    item_price = 555
    item = Store::Item.named_priced_with_owner("TestItem", item_price, nil)
    assert(item.price == item_price)
  end

  def test_item_inactive_after_creation
    item = Store::Item.new
    assert(item.active == false, "New items must be set inactive!")
  end

  def test_item_has_owner
    user = Store::User.named("User")
    item = user.propose_item("TestItem", 100)
    assert(item.owner == user)
  end

  def test_item_valid_price
    p1 = "20"
    p2 = "+20"
    p3 = "020"
    p4 = "-20"
    p5 = ""

    assert(Store::Item.valid_price?(p1), "20 is a valid price")
    assert(Store::Item.valid_price?(p2), "+20 is a valid price")
    assert(!Store::Item.valid_price?(p3), "020 is an invalid price")
    assert(!Store::Item.valid_price?(p4), "-20 is an invalid price")
    assert(!Store::Item.valid_price?(p5), "empty is an invalid price")
  end

  def test_is_editable?
    item = Store::Item.named_priced_with_owner("test",20,nil)
    item.activate
    assert_equal(false,item.editable?)
    item.deactivate
    assert_equal(true,item.editable?)
  end

  def test_change_status
    item = Store::Item.named_priced_with_owner("TestItem", 0, nil)
    assert_equal(false, item.active?)

    item.update_status("true")

    assert_equal(true, item.active?)
  end

  def test_item_update
    item = Store::Item.named_priced_with_owner("TestItem", 0, nil)
    item.update("NewName", 100, "NewDescription")

    assert_equal("NewName", item.name)
    assert_equal(100, item.price)
    assert_equal("NewDescription", item.description)
  end

  def test_item_save
    item = Store::Item.named_priced_with_owner("TestItem", 0, nil)
    item.save
    assert_equal(item, Store::Item.by_id(item.id))
  end

  def test_item_delete
    item = Store::Item.named_priced_with_owner("TestItem", 0, nil)
    item.save
    assert_equal(item, Store::Item.by_id(item.id))

    item.delete
    assert_equal(nil, Store::Item.by_id(item.id))
  end

  def test_get_all_items
    item1 = Store::Item.named_priced_with_owner("TestItem1", 0, nil)
    item2 = Store::Item.named_priced_with_owner("TestItem2", 0, nil)
    item3 = Store::Item.named_priced_with_owner("TestItem3", 0, nil)

    item1.save
    item2.save
    item3.save

    assert_equal([item1, item2, item3], Store::Item.all)
  end
end