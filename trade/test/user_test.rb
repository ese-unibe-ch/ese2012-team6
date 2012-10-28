require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_check_user_name
    name = "HansliCaramell"
    user = Store::User.named(name)

    assert(!user.name.nil? ,"No User Name")
    assert_equal(name,user.name, "Wrong User name")
  end

  def test_user_handling
    (user1 = Store::User.named("me")).save
    (user2 = Store::User.named("you")).save
    assert(Store::User.exists?(:name=>user1.name), "user doesn't exist")
    assert_equal(Store::User.all, [user1, user2], "users not in list")

    user2.delete
    assert(!Store::User.exists?(:name=>user2.name), "user doesn't exist")
    assert_equal(Store::User.by_name(user1.name), Store::User.fetch_by(:name=>user1.name), "methods are not the same")
  end

  def test_default_credits_amount
    default_amount = 100
    user = Store::User.new

    assert_equal(default_amount, user.credits)
  end

  def test_custom_credits_amount
    amount = 123
    user = Store::User.new
    user.credits = amount

    assert_equal(amount, user.credits)
  end

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
  end

  def test_user_organization_creating
    (user = Store::User.named("me")).save
    (member = Store::User.named("you")).save
    (org1 = Store::Organization.named("org1")).save
    (org2 = Store::Organization.named("org2")).save

    org1.add_admin(user)
    assert(user.is_admin_of?(org1), "failed adding admin")
    assert(!user.is_admin_of?(org2), "admin in wrong organization")

    org1.add_member(member)
    org2.add_member(member)
    assert(member.is_member_of?(org1), "failed adding member")
    assert_equal(member.get_organizations, [org1, org2], "is in wrong organization")

  end

  def test_work_as
    (user = Store::User.named("user")).save
    (org = Store::Organization.named("org")).save

    assert(user.working_as_self?, "is not working on behalf of himself")
    assert(!user.working_on_behalf_of?(org), "is working on behalf of this org")

    user.work_on_behalf_of(org)
    assert(user.working_on_behalf_of?(org), "is not working on behalf of this org")
    assert(!user.working_as_self?, "is still working on behalf of himself")
  end
end