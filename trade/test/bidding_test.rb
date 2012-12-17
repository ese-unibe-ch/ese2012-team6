require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/user'
require_relative '../app/models/store/trader'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/item'
require_relative '../app/models/store/auction_timer'

class AuctionTest < Test::Unit::TestCase
  include Store

  def setup
    Trader.clear_all
    @userA = Trader.named("Hans")
    @userB = Trader.named("Horst")
    @userC = Trader.named("Vreni")
    @userD = Trader.named("Penner")
    @userA.credits = 1000
    @userB.credits = 1000
    @userC.credits = 1000
    @userD.credits = 1
  end

  def teardown
    Trader.clear_all
  end

  def test_can_bid
    initial_price = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initial_price, @userA, increment, 0, nil)
    assert item.is_auction?
    assert !item.is_fixed?
    assert(!@userD.can_bid?(item,1)) # bid not high enough
    assert(!@userD.can_bid?(item,2)) # not enough money

    assert(!@userA.can_bid?(item,20))  #auction owner cannot bid
    assert(!@userD.can_bid?(item,5))  #auction owner cannot bid
  end

  def test_create_auction
    initial_price = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initial_price, @userA, increment, 0, nil)
    assert(item.owner == @userA)
    assert(item.current_selling_price == nil)

    assert(@userB.can_bid?(item, 10))

    ###### FIRST BID :: Price = nil
    @userB.bid(item, 10)
    ### AFTER :: Bidders = [10], Price = 5
    assert(item.current_selling_price == 5)

    assert(!@userC.can_bid?(item, 3))
    assert(!@userC.can_bid?(item, 4))
    assert(@userC.can_bid?(item, 7))

    ###### SECOND BID :: Price = 7, Minimal Bid = 7 ######
    @userC.bid(item, 7)
    ### AFTER :: Bidders = [5, 10], Price = 7
    assert(item.current_selling_price == 9)

    assert(!@userC.can_bid?(item, 5))
    assert(!@userC.can_bid?(item, 6))
    assert(@userC.can_bid?(item, 11))

    ###### THIRD BID :: Price = 7, Minimal Bid = 7 ######
    @userC.bid(item, 11)
    ### AFTER :: Bidders = [7, 10], Price = 9

    assert(item.current_selling_price == 11)
  end

  def test_current_winner
    initial_price = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initial_price, @userA, increment, 0, nil)
    assert item.current_winner == nil
    @userB.bid(item, 10)
    assert item.current_winner == @userB
    @userC.bid(item, 15)
    assert item.current_winner == @userC
  end

  # the credit of an user is not reserved any more if bid is not current
  def test_get_money_back_if_overbidden
    initial_price = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initial_price, @userA, increment, "2015-10-15 18:00:00", nil)
    @userB.bid(item,20)
    assert item.current_selling_price == 5
    assert @userA.credits == 1000
    assert @userB.credits == 980
    assert @userC.credits == 1000
    @userC.bid(item,15)
    assert item.current_selling_price == 17
    assert @userA.credits == 1000
    assert @userB.credits == 980
    assert @userC.credits == 1000
    @userC.bid(item,25)
    assert item.current_selling_price == 22
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 975
  end

  # an auction with a placed bid can not be changed from the owner
  def test_cant_edit_after_bidding
    initial_price = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initial_price, @userA, increment, 0, nil)
    assert item.editable?
    @userB.bid(item,20)
    assert !item.editable?
  end

  def test_finish_transaction
    initial_price = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initial_price, @userA, increment, "2009-10-15 18:00:00", nil)
    @userB.bid(item,20)
    @userC.bid(item,15)
    @userC.bid(item,25)
    @userC.bid(item,30)
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 970
    AuctionTimer.finish_auction(item)
    assert item.bidders == {}
    assert_equal(22, item.price)
    assert_equal(1024, @userA.credits)
    assert @userB.credits == 1000
    assert_equal(978, @userC.credits)
  end

  def test_finish_transaction_no_bidder
    initial_price = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initial_price, @userA, increment, "2009-10-15 18:00:00", nil)
    item.activate
    AuctionTimer.finish_auction(item)
    assert @userA.credits == 1000
    assert !item.active?
  end

  # if no winner exists then get reserved money back
  def test_get_money_back_when_deactivated
    initial_price = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initial_price, @userA, increment, "2015-10-15 18:00:00", nil)
    @userB.bid(item,20)
    @userC.bid(item,15)
    @userC.bid(item,25)
    @userC.bid(item,30)
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 970
    item.deactivate
    assert item.bidders == {}
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 1000
    item.activate
    assert item.bidders == {}
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 1000
  end
end