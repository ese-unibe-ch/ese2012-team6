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

  def test_edit_activity
    editor = Store::User.named("Editor")
    item = editor.propose_item("TestItem", 100)
    old_vals = {:name => item.name, :price => item.price, :description => item.description}
    new_vals = {:name => "new_name", :price => 120, :description => "new_desc"}
    edit_activity = Analytics::ItemEditActivity.with_editor_item_old_new_vals(editor, item, old_vals, new_vals)
    assert_equal(Analytics::ActivityType::ITEM_EDIT, edit_activity.type)
    assert_equal(editor.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
    assert_equal(old_vals, edit_activity.old_values)
    assert_equal(new_vals, edit_activity.new_values)
  end

  def test_status_change_activity
    editor = Store::User.named("Editor")
    item = editor.propose_item("TestItem", 100)
    edit_activity = Analytics::ItemStatusChangeActivity.with_editor_item_status(editor, item, true)
    assert_equal(Analytics::ActivityType::ITEM_STATUS_CHANGE, edit_activity.type)
    assert_equal(editor.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
    assert_equal(true, edit_activity.new_status)
  end

  def test_delete_activity
    remover = Store::User.named("Remover")
    item = remover.propose_item("TestItem", 100)
    edit_activity = Analytics::ItemDeleteActivity.with_remover_item(remover, item)
    assert_equal(Analytics::ActivityType::ITEM_DELETE, edit_activity.type)
    assert_equal(remover.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
  end
end