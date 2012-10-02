require 'test/unit'
require '../app/models/store/item'
require '../app/models/store/user'

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

end