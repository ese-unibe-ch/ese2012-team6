require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/user'
require_relative '../app/models/store/system_user'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/item'

class SystemUserTest < Test::Unit::TestCase
  include Store

  def setup
    SystemUser.clear_all
  end

  def teardown
    SystemUser.clear_all
  end

  def test_creation_default
    user = SystemUser.named("Hans")
    assert_equal(0, user.credits)
    assert_equal("", user.description)
    assert_equal(0, user.items.size)
    assert_equal("/images/no_image.gif", user.image_path)
  end

  def test_creation_with_credits
    user = SystemUser.named("Hans", :credits => 100)
    assert_equal(100, user.credits)
  end

  def test_creation_with_description
    user = SystemUser.named("Hans", :description => "New description")
    assert_equal("New description", user.description)
  end

  def test_user_proposes_item
    user = SystemUser.named("User")
    item = user.propose_item("TestItem", 100)

    assert_equal(false, item.active, "Newly created items must be inactive!")
    assert_equal(user, item.owner , "Item with no assigned owner created!")
  end

  def test_fetch_by_name
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(user, SystemUser.fetch_by(:name => "User1"))
    assert_equal(org, SystemUser.fetch_by(:name => "Org1"))
  end

  def test_fetch_by_id
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(user, SystemUser.fetch_by(:id => 1))
    assert_equal(org, SystemUser.fetch_by(:id => 2))
  end

  def test_fetch_all
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal([user, org], SystemUser.all)
  end

  def test_by_name_and_id
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(user, SystemUser.by_name("User1"))
    assert_equal(org, SystemUser.by_name("Org1"))
  end

  def test_exists_by_name
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(true, SystemUser.exists?(:name => "User1"))
    assert_equal(true, SystemUser.exists?(:name => "Org1"))
    assert_equal(false, SystemUser.exists?(:name => "User2"))
    assert_equal(false, SystemUser.exists?(:name => "Org2"))
  end

  def test_exists_by_id
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(true, SystemUser.exists?(:id => 1))
    assert_equal(true, SystemUser.exists?(:id => 2))
    assert_equal(false, SystemUser.exists?(:id => 3))
    assert_equal(false, SystemUser.exists?(:id => 4))
  end

  def test_user_active_items_list
    user = SystemUser.named("User")

    user.propose_item("TestItem1", 1)
    item2 = user.propose_item("TestItem2", 2)
    user.propose_item("TestItem3", 3)
    item4 = user.propose_item("TestItem4", 4)

    item2.activate
    item4.activate

    active_items = [item2, item4]
    active_items_user = user.get_active_items

    # '==' operator of Array class tests for equal length and matching elements, does not compare references!
    assert_equal(active_items, active_items_user, "Item lists do not match!")
  end

  def test_user_buy_success
    buyer = SystemUser.named("Buyer", :credits => 100)
    seller = SystemUser.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100)
    item.activate

    buyer.acknowledge_item_properties!

    transaction_result, transaction_message = buyer.buy_item(item)
    assert(transaction_result, "Transaction failed when it should have succeeded\nReason: #{transaction_message}")

    assert_equal(0, buyer.credits, "Buyer has too many credits left")
    assert_equal(205, seller.credits, "Seller has too few credits")

    assert(!seller.items.include?(item), "Seller still owns the sold item")
    assert(buyer.items.include?(item), "Buyer doesn't have the item")
    assert_equal(buyer, item.owner, "Item has the wrong owner")

    assert(!item.active?, "Item is still active")
  end

  def test_user_buy_inactive_item
    buyer = SystemUser.named("Buyer", :credits => 100)
    seller = SystemUser.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100)
    buyer.acknowledge_item_properties!
    assert(!item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)
    puts transaction_message

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert_equal(100, buyer.credits, "Buyer's credits changed when they should not have")
    assert_equal(100, seller.credits, "Seller's credits changed when they should not have")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_user_buy_too_expensive
    buyer = SystemUser.named("Buyer", :credits => 100)
    seller = SystemUser.named("Seller", :credits => 100)

    item = seller.propose_item("big piece of crap", 9001) #item price is over 9000!
    item.activate
    buyer.acknowledge_item_properties!
    assert(item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)
    puts transaction_message

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert_equal(100, buyer.credits, "Buyer has wrong amount of credits")
    assert_equal(100, seller.credits, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_reduce_credits
    user = SystemUser.named("User", :credits => 200)

    user.reduce_credits

    assert(200 - Integer(SystemUser::CREDIT_REDUCE_RATE * 200), user.credits)
  end

  def test_reduce_credits_all
    (user = User.named("User1")).save
    (org = Organization.named("Org1", :credits => 200)).save

    SystemUser.reduce_credits

    assert_equal(100 - Integer(SystemUser::CREDIT_REDUCE_RATE * 100), user.credits)
    assert_equal(200 - Integer(SystemUser::CREDIT_REDUCE_RATE * 200), org.credits)
  end

  def test_send_money_to
    user1 = SystemUser.named("User1", :credits => 100)
    user2 = SystemUser.named("User2", :credits => 100)

    user1.send_money_to(user2, 50)

    assert_equal(50, user1.credits)
    assert_equal(150, user2.credits)
  end

  def test_notice_item_change_fail
    seller = Store::User.named("seller")
    buyer = Store::User.named("buyer")
    item = seller.propose_item("item", 2);

    buyer.acknowledge_item_properties!

    # change item while buyer is not looking
    item.deactivate
    item.update("newName", 3, "aölsdfjaldf", false)
    item.activate

    assert_equal(false, buyer.knows_item_properties?(item))
    assert_equal([false, "item_changed_details"] , buyer.buy_item(item, false))
  end

  def test_notice_item_change_success
    seller = Store::User.named("seller")
    buyer = Store::User.named("buyer")
    item = seller.propose_item("item", 2);

    buyer.acknowledge_item_properties!

    # change item while buyer is not looking
    item.deactivate
    item.update("newName", 3, "aölsdfjaldf", false)
    item.activate

    # buyer looks at item
    buyer.acknowledge_item_properties!

    assert_equal(true, buyer.knows_item_properties?(item))
    assert_equal(true , buyer.buy_item(item, false)[0])
  end
end