require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'
require_relative '../app/models/store/system_user'

class UserTest < Test::Unit::TestCase
  def test_check_organization_name
    name = "Umbrella Corp."
    organization = Store::Organization.named(name)

    assert(!organization.name.nil? ,"No User Name")
    assert_equal(name,organization.name, "Wrong User name")
  end

  def test_organization_handling
    (org1 = Store::Organization.named("me")).save
    (org2 = Store::Organization.named("you")).save
    assert(Store::Organization.exists?(:name=>org1.name), "org doesn't exist")
    assert_equal(Store::Organization.all, [org1,org2], "organizations not in list")

    org2.delete
    assert(!Store::Organization.exists?(:name=>org2.name), "org doesn't exist")
    assert(Store::Organization.fetch_by(:id=>org1.id), "also removed org1")
  end

  def test_add_and_remove_admin
    user1 = Store::User.named("admin")
    user2 = Store::User.named("user")
    organization = Store::Organization.named("new")
    organization.add_admin(user1)
    assert(organization.has_admin?(user1), "failed adding admin")
    assert(!organization.has_admin?(user2), "wrong admin added")

    organization.add_admin(user2)
    organization.remove_admin(user1)
    assert(!organization.has_admin?(user1), "user is still admin")
    assert(organization.admins.include?(user2), "wrong user as admin")
  end

  def test_add_and_remove_member
    org_name = "org"
    member_name = "you"
    organization = Store::Organization.named(org_name)
    member = Store::User.named(member_name)
    member2 = Store::User.named("him")

    organization.add_member(member)
    assert(organization.has_member?(member), "member not in list")
    assert(organization.members.include?(member), "false member added")
    assert(!organization.members.include?(member2), "not added as member")

    organization.remove_member(member)
    assert(!organization.members.include?(member), "remove member failed")
    assert(!organization.has_member?(member), "member still in list")
  end

  def test_default_credits_amount
    default_amount = 0
    organization = Store::Organization.new

    assert(organization.credits == default_amount)
  end

  def test_custom_credits_amount
    amount = 123
    organization = Store::Organization.new
    organization.credits = amount

    assert(organization.credits == amount)
  end

  def test_user_proposes_item
    organization = Store::Organization.named("Umbrella Corp.")
    item = organization.propose_item("TestItem", 100)

    assert(item.active == false, "Newly created items must be inactive!")
    assert(item.owner == organization, "Item with no assigned owner created!")
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
    assert(active_items == active_items_user, "Item lists do not match!")
  end

  def test_user_buy_success
    buyer = Store::User.named("Buyer")
    seller = Store::User.named("Seller")

    item = seller.propose_item("piece of crap", 100)
    item.activate

    transaction_result, transaction_message = buyer.buy_item(item)
    assert(transaction_result == true, "Transaction failed when it should have succeeded\nReason: #{transaction_message}")

    assert(buyer.credits == 0, "Buyer has too many credits left")
    assert(seller.credits != 200, "Seller has too few credits")

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
    item.activate

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