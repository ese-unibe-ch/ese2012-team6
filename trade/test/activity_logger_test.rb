require 'test/unit'
require 'require_relative'
require_relative '../app/models/analytics/activity'
require_relative '../app/models/store/user'
require_relative '../app/models/store/item'

class ActivityLoggerTest < Test::Unit::TestCase
  def test_log_activity
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100, "", false) #don't log item creation

    act1 = Analytics::ItemAddActivity.with_creator_item(user, item)
    act2 = Analytics::ItemDeleteActivity.with_remover_item(user, item)

    Analytics::ActivityLogger.log(act1)
    Analytics::ActivityLogger.log(act2)

    logged_activities = Analytics::ActivityLogger.get_all_activities

    assert_equal(Analytics::ActivityType::ITEM_ADD, logged_activities[1].type)
    assert_equal(item.id, logged_activities[1].item_id)
    assert_equal(user.name, logged_activities[1].actor_name)

    assert_equal(Analytics::ActivityType::ITEM_DELETE, logged_activities[0].type)
    assert_equal(item.id, logged_activities[0].item_id)
    assert_equal(user.name, logged_activities[0].actor_name)
  end

  def test_get_all_activities
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100, "", false) #don't log item creation

    act1 = Analytics::ItemDeleteActivity.with_remover_item(user, item)
    act2 = Analytics::ItemAddActivity.with_creator_item(user, item)
    act3 = Analytics::ItemEditActivity.with_editor_item_old_new_vals(user, item, {}, {})
    act4 = Analytics::ItemBuyActivity.with_buyer_item_price_success(user, item)

    Analytics::ActivityLogger.log(act1)
    Analytics::ActivityLogger.log(act2)
    Analytics::ActivityLogger.log(act3)
    Analytics::ActivityLogger.log(act4)

    assert_equal([act4, act3, act2, act1], Analytics::ActivityLogger.get_all_activities)
  end

  def test_previous_description
    user = Store::User.named("Hans")
    item = user.propose_item("Test", 100, "Previous Description", false)

    item.update("Test", 100, "New Description")

    assert("Previous Description", Analytics::ActivityLogger.get_previous_description(item))
  end

  def test_recent_purchases
    user = Store::User.named("Hansli")
    user2 = Store::User.named("Fritzli")
    item = user.propose_item("Test1", 100, "", false)
    item2 = user2.propose_item("Test2", 100, "", false)

    item.activate
    item2.activate

    user.buy_item(item2)
    user2.buy_item(item)

    recent_purchases = Analytics::ActivityLogger.get_most_recent_purchases(2)

    assert_equal(recent_purchases.size, 2)

    assert_equal("Hansli", recent_purchases[1].actor_name)
    assert_equal(item2.id, recent_purchases[1].item_id)
    assert_equal("Fritzli", recent_purchases[0].actor_name)
    assert_equal(item.id, recent_purchases[0].item_id)
  end
end