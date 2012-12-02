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

  def test_canBid
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert item.isAuction?
    assert !item.isFixed?
    assert(!@userD.canBid?(item,1)) # bid not high enough
    assert(!@userD.canBid?(item,2)) # not enough money

    assert(!@userA.canBid?(item,4)) # bid not high enough
    assert(@userA.canBid?(item,5))  # bid high enough & enough money
  end

  def test_createAuction
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert(item.owner == @userA)
    assert(item.currentSellingPrice == nil)

    assert(@userB.canBid?(item, 10))

    ###### FIRST BID :: Price = nil
    @userB.bid(item, 10)
    ### AFTER :: Bidders = [10], Price = 5
    assert(item.currentSellingPrice == 5)

    assert(!@userC.canBid?(item, 3))
    assert(!@userC.canBid?(item, 4))
    assert(@userC.canBid?(item, 5))

    ###### SECOND BID :: Price = 5, Minimal Bid = 5 ######
    @userC.bid(item, 5)
    ### AFTER :: Bidders = [5, 10], Price = 7
    assert(item.currentSellingPrice == 7)

    assert(!@userC.canBid?(item, 5))
    assert(!@userC.canBid?(item, 6))
    assert(@userC.canBid?(item, 7))

    ###### THIRD BID :: Price = 7, Minimal Bid = 7 ######
    @userC.bid(item, 7)
    ### AFTER :: Bidders = [7, 10], Price = 9

    assert(item.currentSellingPrice == 9)
  end

  def test_current_winner
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert item.current_winner == nil
    @userB.bid(item, 10)
    assert item.current_winner == @userB
    @userC.bid(item, 15)
    assert item.current_winner == @userC
  end

  def test_get_money_back_if_overbidden
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initialPrice, @userA, increment, "2015-10-15 18:00:00", nil)
    @userB.bid(item,20)
    assert item.currentSellingPrice == 5
    assert @userA.credits == 1000
    assert @userB.credits == 980
    assert @userC.credits == 1000
    @userC.bid(item,15)
    assert item.currentSellingPrice == 17
    assert @userA.credits == 1000
    assert @userB.credits == 980
    assert @userC.credits == 1000
    @userC.bid(item,25)
    assert item.currentSellingPrice == 22
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 975
  end

  def test_cant_edit_after_bidding
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert item.editable?
    @userB.bid(item,20)
    assert !item.editable?
  end

  def test_finish_transaction
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initialPrice, @userA, increment, "2009-10-15 18:00:00", nil)
    @userB.bid(item,20)
    @userC.bid(item,15)
    @userC.bid(item,25)
    @userC.bid(item,30)
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 970
    AuctionTimer.finish_auction(item)
    assert item.bidders == {}
    assert @userA.credits == 1022
    assert @userB.credits == 1000
    assert @userC.credits == 978
  end

  def test_finish_transaction_no_bidder
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initialPrice, @userA, increment, "2009-10-15 18:00:00", nil)
    item.activate
    AuctionTimer.finish_auction(item)
    assert @userA.credits == 1000
    assert !item.active?
  end

  def test_get_money_back_when_deactivated
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.auction(item_name, initialPrice, @userA, increment, "2015-10-15 18:00:00", nil)
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