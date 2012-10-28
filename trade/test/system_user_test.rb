
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_user_proposes_item
    user = Store::User.named("User")
    item = user.propose_item("TestItem", 100)

    assert_equal(false, item.active, "Newly created items must be inactive!")
    assert_equal(user, item.owner , "Item with no assigned owner created!")
  end

  def test_user_active_items_list
    user = Store::User.named("User")

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
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("piece of crap", 100)
    item.activate

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
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("piece of crap", 100)

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
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("big piece of crap", 9001) #item price is over 9000!
    item.activate

    assert(item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)
    puts transaction_message

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert_equal(100, buyer.credits, "Buyer has wrong amount of credits")
    assert_equal(100, seller.credits, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
=======
require "test/unit"
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/system_user'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'

class SystemUserTest < Test::Unit::TestCase

  def setup

  end

  # Fake test
  def test_fail

    # To change this template use File | Settings | File Templates.
    fail("Not implemented")
>>>>>>> origin/mh
  end
end