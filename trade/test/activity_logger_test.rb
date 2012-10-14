require 'test/unit'
require 'require_relative'
require_relative '../app/models/analytics/activity'
require_relative '../app/models/store/user'
require_relative '../app/models/store/item'

class ActivityLoggerTest < Test::Unit::TestCase
  def test_log_activity
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100)

    act2 = Analytics::ItemDeleteActivity.with_remover_item(user, item)

    Analytics::ActivityLogger.log_activity(act2)

    logged_activities = Storage::Database.instance.get_all_activities

    assert_equal(Analytics::ActivityType::ITEM_ADD, logged_activities[0].type)
    assert_equal(item.id, logged_activities[0].item_id)
    assert_equal(user.name, logged_activities[0].actor_name)

    assert_equal(Analytics::ActivityType::ITEM_DELETE, logged_activities[1].type)
    assert_equal(item.id, logged_activities[1].item_id)
    assert_equal(user.name, logged_activities[1].actor_name)

    Storage::Database.instance.clear_activities
  end

  def test_get_all_activities
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100)

    act1 = Analytics::ItemDeleteActivity.with_remover_item(user, item)
    act2 = Analytics::ItemAddActivity.with_creator_item(user, item)
    act3 = Analytics::ItemEditActivity.with_editor_item_old_new_vals(user, item, {},{})
    act4 = Analytics::ItemBuyActivity.with_buyer_item_price(user, item)

    Storage::Database.instance.add_activity(act1)
    Storage::Database.instance.add_activity(act2)
    Storage::Database.instance.add_activity(act3)
    Storage::Database.instance.add_activity(act4)

    assert_equal([act1, act2, act3, act4], Analytics::ActivityLogger.get_all_activities[1..4])
    Storage::Database.instance.clear_activities
  end

  def test_previous_description
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100, "Previous Description")

    item.update("Test", 100, "New Description")

    assert("Previous Description", Analytics::ActivityLogger.get_previous_description(item))
    Storage::Database.instance.clear_activities
  end

  def test_recent_purchases
    user = Store::User.named("Hans")
    user2 = Store::User.named("Fritz")
    item = user.propose_item("Test1", 100)
    item2 = user2.propose_item("Test2", 100)

    item.set_active
    item2.set_active

    user.buy_item(item2)
    user2.buy_item(item)

    recent_purchases = Analytics::ActivityLogger.get_most_recent_purchases(2)

    assert_equal(recent_purchases.size, 2)

    assert_equal(recent_purchases[0].actor_name, "Hans")
    assert_equal(recent_purchases[0].item_id, item2.id)
    assert_equal(recent_purchases[1].actor_name, "Fritz")
    assert_equal(recent_purchases[1].item_id, item.id)
    Storage::Database.instance.clear_activities
  end
end