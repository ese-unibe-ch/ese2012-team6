require 'test/unit'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_check_user_name
    name = "HansliCaramell"
    user = Store::User.named(name)

    assert(!user.name.nil? ,"No User Name")
    assert_equal(name,user.name, "Wrong User name")
  end

  def test_default_credits_amount
    default_amount = 100
    user = Store::User.new

    assert(user.credits == default_amount)
  end

  def test_custom_credits_amount
    amount = 123
    user = Store::User.new
    user.credits = amount

    assert(user.credits == amount)
  end

  def test_user_proposes_item
    user = Store::User.named("User")
    item = user.propose_item("TestItem", 100)

    assert(item.active == false, "Newly created items must be inactive!")
    assert(item.owner == user, "Item with no assigned owner created!")
  end

  def test_user_active_items_list
    user = Store::User.named("User")

    user.propose_item("TestItem1", 1)
    item2 = user.propose_item("TestItem2", 2)
    user.propose_item("TestItem3", 3)
    item4 = user.propose_item("TestItem4", 4)

    item2.set_active
    item4.set_active

    active_items = [item2, item4]
    active_items_user = user.get_active_items

    # '==' operator of Array class tests for equal length and matching elements, does not compare references!
    assert(active_items == active_items_user, "Item lists do not match!")
  end

  def test_user_buy_success
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("piece of crap", 100)
    item.set_active

    transaction_result, transaction_message = buyer.buy_item(item)
    assert(transaction_result == true, "Transaction failed when it should have succeeded\nReason: #{transaction_message}")

    assert(buyer.credits == 0, "Buyer has too many credits left")
    assert(seller.credits == 200, "Seller has too few credits")

    assert(!seller.items.include?(item), "Seller still owns the sold item")
    assert(buyer.items.include?(item), "Buyer doesn't have the item")
    assert(item.owner == buyer, "Item has the wrong owner")

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

    assert(buyer.credits == 100, "Buyer's credits changed when they should not have")
    assert(seller.credits == 100, "Seller's credits changed when they should not have")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert(item.owner == seller, "Item has the wrong owner")
  end

  def test_user_buy_too_expensive
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("big piece of crap", 9001) #item price is over 9000!
    item.set_active

    assert(item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)
    puts transaction_message

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert(buyer.credits == 100, "Buyer has wrong amount of credits")
    assert(seller.credits == 100, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert(item.owner == seller, "Item has the wrong owner")
  end
end