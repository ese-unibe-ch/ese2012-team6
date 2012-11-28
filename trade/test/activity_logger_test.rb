require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/analytics/activity'
require_relative '../app/models/store/user'
require_relative '../app/models/store/item'
require_relative '../app/models/store/purchase'

class ActivityLoggerTest < Test::Unit::TestCase
  include Analytics
  include Store
  
  def setup
    ActivityLogger.clear
  end

  def teardown
    ActivityLogger.clear
  end

  def test_log_activity
    user = User.named("Hans")
    item = user.propose_item("Test", 100, :fixed, nil, nil, "", false) #don't log item creation

    act1 = ItemAddActivity.with_creator_item(user, item)
    act2 = ItemDeleteActivity.with_remover_item(user, item)

    ActivityLogger.log(act1)
    ActivityLogger.log(act2)

    logged_activities = ActivityLogger.get_all_activities

    assert_equal(ActivityType::ITEM_ADD, logged_activities[1].type)
    assert_equal(item.id, logged_activities[1].item_id)
    assert_equal(user.name, logged_activities[1].actor_name)

    assert_equal(ActivityType::ITEM_DELETE, logged_activities[0].type)
    assert_equal(item.id, logged_activities[0].item_id)
    assert_equal(user.name, logged_activities[0].actor_name)
  end

  def test_get_all_activities
    user = User.named("Hans")
    item = user.propose_item("Test", 100, :fixed, nil, nil, 1, "", false) #don't log item creation

    act1 = ItemDeleteActivity.with_remover_item(user, item)
    act2 = ItemAddActivity.with_creator_item(user, item)
    act3 = ItemEditActivity.with_editor_item_old_new_vals(user, item, {}, {})
    act4 = ItemBuyActivity.with_buyer_item_price_success(user, item)

    ActivityLogger.log(act1)
    ActivityLogger.log(act2)
    ActivityLogger.log(act3)
    ActivityLogger.log(act4)

    assert_equal([act4, act3, act2, act1], ActivityLogger.get_all_activities)
  end

  def test_previous_description
    user = User.named("Hans")
    item = user.propose_item("Test", 100, :fixed, nil, nil, "Previous Description", false)

    item.update("Test", 100, "New Description", :fixed, nil, nil)

    assert("Previous Description", ActivityLogger.get_previous_description(item))
  end

  def test_recent_purchases
    user = User.named("Hansli")
    user2 = User.named("Fritzli")
    item = user.propose_item("Test1", 100, :fixed, nil, nil,1, "", false)
    item2 = user2.propose_item("Test2", 100, :fixed, nil, nil,1, "", false)

    item.activate
    item2.activate

    [user, user2].each{ |usr| usr.acknowledge_item_properties! }

    user.purchase(item2)
    user.confirm_all_pending_purchases

    user2.purchase(item)
    user.confirm_all_pending_purchases

    recent_purchases = ActivityLogger.get_most_recent_purchases(2)

    assert_equal(2, recent_purchases.size)

    assert_equal("Hansli", recent_purchases[1].actor_name)
    assert_equal(item2.id, recent_purchases[1].item_id)
    assert_equal("Fritzli", recent_purchases[0].actor_name)
    assert_equal(item.id, recent_purchases[0].item_id)
  end
end