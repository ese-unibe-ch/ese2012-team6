require 'test/unit'
require 'require_relative'
require_relative '../app/models/analytics/activity'
require_relative '../app/models/store/user'
require_relative '../app/models/store/item'

class ActivityTest < Test::Unit::TestCase
  def test_activity_creation
    activity = Analytics::Activity.new
    assert_equal(Analytics::ActivityType::NONE, activity.type)
  end

  def test_buy_activity
    buyer = Store::User.named("Buyer")
    item = buyer.propose_item("TestItem", 100)
    buy_activity = Analytics::ItemBuyActivity.with_buyer_item_price(buyer, item)
    assert_equal(Analytics::ActivityType::ITEM_BUY, buy_activity.type)
    assert_equal(buyer.name, buy_activity.actor_name)
    assert_equal(item.id, buy_activity.item_id)
    assert_equal(item.price, buy_activity.price)
  end

  def test_add_activity
    creator = Store::User.named("Creator")
    item = creator.propose_item("TestItem", 100)
    edit_activity = Analytics::ItemAddActivity.with_creator_item(creator, item)
    assert_equal(Analytics::ActivityType::ITEM_ADD, edit_activity.type)
    assert_equal(creator.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
  end
end