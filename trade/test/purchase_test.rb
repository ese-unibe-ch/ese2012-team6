require "test/unit"
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/trading_authority'
require_relative '../app/models/store/user'
require_relative '../app/models/store/trader'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/item'
require_relative '../app/models/store/purchase'
require_relative '../app/models/helpers/exceptions/purchase_error'

class PurchaseTest < Test::Unit::TestCase
  include Store

  def teardown
    Trader.clear_all
  end

  def test_create_item_with_quantity
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (my_item = me.propose_item_with_quantity("One", 7, 1, :fixed, nil, nil)).activate
    (your_item = you.propose_item_with_quantity("Four", 11, 4, :fixed, nil, nil)).activate

    assert_equal(me.items, [my_item])
    assert(my_item.quantity == 1)
    assert_equal(you.items, [your_item])
    assert(your_item.quantity == 4)
  end

  def test_make_a_purchase
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (my_item = me.propose_item_with_quantity("One", 7, 1, :fixed, nil, nil)).activate

    purchase = you.purchase(my_item, 1)

    assert(my_item.state == :pending)
    assert(my_item.quantity == 1)
    assert(you.credits == 93)
    assert(me.credits == 100)
    assert_equal(you.pending_purchases, [purchase])
  end

  def test_confirm_purchase
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (my_item = me.propose_item_with_quantity("One", 7, 1, :fixed, nil, nil)).activate

    purchase = you.purchase(my_item, 1)
    you.confirm_purchase(purchase)

    assert(my_item.state == :inactive)
    assert(my_item.quantity == 1)
    assert(you.credits == 93)
    assert(me.credits == 108)
    assert_equal(you.pending_purchases, [])
  end

  def test_make_several_purchases
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (your_item = you.propose_item_with_quantity("Four", 11, 4, :fixed, nil, nil)).activate

    purchase = me.purchase(your_item, 2)

    assert(your_item.state == :active)
    assert(your_item.quantity == 2)
    assert(me.credits == 78)
    assert(you.credits == 100)
    assert_equal(me.pending_purchases, [purchase])
  end

  def test_confirm_several_purchases
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (your_item = you.propose_item_with_quantity("Four", 11, 4, :fixed, nil, nil)).activate

    purchase = me.purchase(your_item, 2)
    me.confirm_purchase(purchase)

    assert(your_item.state == :active)
    assert(your_item.quantity == 2)
    assert(me.credits == 78)
    assert(you.credits == 124)
    assert_equal(me.pending_purchases, [])
  end

  def test_make_different_purchases
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (my_item = me.propose_item_with_quantity("One", 7, 1, :fixed, nil, nil)).activate
    (your_item = you.propose_item_with_quantity("Four", 11, 4, :fixed, nil, nil)).activate

    purchase1 = me.purchase(your_item, 2)
    purchase2 = me.purchase(your_item, 1)
    purchase3 = you.purchase(my_item, 1)

    assert(your_item.state == :active)
    assert(my_item.state == :pending)
    assert(your_item.quantity == 1)
    assert(my_item.quantity == 1)
    assert(me.credits == 67)
    assert(you.credits == 93)
    assert_equal(me.pending_purchases, [purchase1, purchase2])
    assert_equal(you.pending_purchases, [purchase3])
  end

  def test_confirm_different_purchases
    me = Trader.named("Me", :credits => 100)
    you = Trader.named("You", :credits => 100)
    (my_item = me.propose_item_with_quantity("One", 7, 1, :fixed, nil, nil)).activate
    (your_item = you.propose_item_with_quantity("Three", 11, 3, :fixed, nil, nil)).activate

    purchase1 = me.purchase(your_item, 2)
    purchase2 = me.purchase(your_item, 1)
    purchase3 = you.purchase(my_item, 1)

    purchased_item = purchase1.item

    me.confirm_purchase(purchase1)
    me.confirm_purchase(purchase2)
    you.confirm_purchase(purchase3)

    assert_equal(nil, Item.by_id(your_item.id))
    assert_equal(:inactive, purchased_item.state)
    assert_equal(:inactive, my_item.state)
    assert_equal(3, purchased_item.quantity)
    assert_equal(purchase2.item, your_item)

    assert_equal(my_item.owner, you)
    assert(me.credits == 75)
    assert(you.credits == 129)
    assert_equal(me.pending_purchases, [])
    assert_equal(you.pending_purchases, [])
    assert_equal(me.non_pending_items, me.items)
  end

  def test_user_buy_success
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100, :fixed, nil, nil)
    item.activate

    buyer.acknowledge_item_properties!

    purchase = nil

    assert_nothing_raised(Exceptions::PurchaseError) { purchase = buyer.purchase(item) }

    assert_equal(0, buyer.credits, "Buyer has too many credits left")
    assert_equal(100, seller.credits, "Seller has too few credits")

    buyer.confirm_purchase(purchase)
    assert_equal(205, seller.credits)

    assert(!seller.items.include?(item), "Seller still owns the sold item")
    assert(buyer.items.include?(item), "Buyer doesn't have the item")
    assert_equal(buyer, item.owner, "Item has the wrong owner")

    assert(!item.active?, "Item is still active")
  end

  def test_user_buy_inactive_item
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100, :fixed, nil, nil)
    buyer.acknowledge_item_properties!
    assert(!item.active?)

    assert_raise(Exceptions::PurchaseError) { buyer.purchase(item) }

    assert_equal(100, buyer.credits, "Buyer's credits changed when they should not have")
    assert_equal(100, seller.credits, "Seller's credits changed when they should not have")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_user_buy_too_expensive
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("big piece of crap", 9001, :fixed, nil, nil) #item price is over 9000!
    item.activate
    buyer.acknowledge_item_properties!
    assert(item.active?)

    assert_raise(Exceptions::PurchaseError) { buyer.purchase(item) }

    assert_equal(100, buyer.credits, "Buyer has wrong amount of credits")
    assert_equal(100, seller.credits, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_user_wants_higher_quantity_than_available
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item_with_quantity("piece of crap", 50, 1, :fixed, nil, nil)
    item.activate

    buyer.acknowledge_item_properties!

    assert_raise(Exceptions::PurchaseError) { buyer.purchase(item, 2) }

    assert_equal(100, buyer.credits, "Buyer has wrong amount of credits")
    assert_equal(100, seller.credits, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_settle_purchase
    seller = User.named("seller", :credits => 100)
    buyer = User.named("buyer", :credits => 100)

    item = seller.propose_item("item", 50, :fixed, nil, nil)
    TradingAuthority.settle_item_purchase(seller, item)

    assert_equal(153, seller.credits)
    assert_equal(100, buyer.credits)
  end
end