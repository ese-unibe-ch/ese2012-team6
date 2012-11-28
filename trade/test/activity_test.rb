require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/analytics/activity'
require_relative '../app/models/store/user'
require_relative '../app/models/store/item'

class ActivityTest < Test::Unit::TestCase
  include Store
  include Analytics
  
  def test_activity_creation
    activity = ItemActivity.new
    assert_equal(ActivityType::NONE, activity.type)
  end

  def test_buy_activity
    buyer = User.named("Buyer")
    item = buyer.propose_item("TestItem", 100, :fixed, nil, nil)
    buy_activity = ItemBuyActivity.with_buyer_item_price_success(buyer, item)
    assert_equal(ActivityType::ITEM_BUY, buy_activity.type)
    assert_equal(buyer.name, buy_activity.actor_name)
    assert_equal(item.id, buy_activity.item_id)
    assert_equal(item.price, buy_activity.price)
  end

  def test_add_activity
    creator = User.named("Creator")
    item = creator.propose_item("TestItem", 100, :fixed, nil, nil)
    edit_activity = ItemAddActivity.with_creator_item(creator, item)
    assert_equal(ActivityType::ITEM_ADD, edit_activity.type)
    assert_equal(creator.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
  end

  def test_edit_activity
    editor = User.named("Editor")
    item = editor.propose_item("TestItem", 100, :fixed, nil, nil)
    old_vals = {:name => item.name, :price => item.price, :description => item.description}
    new_vals = {:name => "new_name", :price => 120, :description => "new_desc"}
    edit_activity = ItemEditActivity.with_editor_item_old_new_vals(editor, item, old_vals, new_vals)
    assert_equal(ActivityType::ITEM_EDIT, edit_activity.type)
    assert_equal(editor.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
    assert_equal(old_vals, edit_activity.old_values)
    assert_equal(new_vals, edit_activity.new_values)
  end

  def test_status_change_activity
    editor = User.named("Editor")
    item = editor.propose_item("TestItem", 100, :fixed, nil, nil)
    edit_activity = ItemStatusChangeActivity.with_editor_item_status(editor, item, true)
    assert_equal(ActivityType::ITEM_STATUS_CHANGE, edit_activity.type)
    assert_equal(editor.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
    assert_equal(true, edit_activity.new_status)
  end

  def test_delete_activity
    remover = User.named("Remover")
    item = remover.propose_item("TestItem", 100, :fixed, nil, nil)
    edit_activity = ItemDeleteActivity.with_remover_item(remover, item)
    assert_equal(ActivityType::ITEM_DELETE, edit_activity.type)
    assert_equal(remover.name, edit_activity.actor_name)
    assert_equal(item.id, edit_activity.item_id)
  end
end