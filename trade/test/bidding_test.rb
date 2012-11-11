require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/user'
require_relative '../app/models/store/trader'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/item'

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
    item = Item.named_priced_with_owner_auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert(!@userD.canBid?(item,1)) # bid not high enough
    assert(!@userD.canBid?(item,2)) # not enough money

    assert(!@userA.canBid?(item,4)) # bid not high enough
    assert(@userA.canBid?(item,5))  # bid high enough & enough money
  end

  def test_createAuction
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = Item.named_priced_with_owner_auction(item_name, initialPrice, @userA, increment, 0, nil)
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
    item = Item.named_priced_with_owner_auction(item_name, initialPrice, @userA, increment, 0, nil)
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
    item = Item.named_priced_with_owner_auction(item_name, initialPrice, @userA, increment, 0, nil)
    @userB.bid(item,20)
    assert @userB.credits = 980
    @userC.bid(item,15)
    assert @userB.credits = 980
    assert @userC.credits = 1000
    @userC.bid(item,25)
    assert@userB.credits = 1000
    assert@userC.credits = 975
  end

  def test_cant_edit_after_bidding
    initialPrice = 5
    increment = 2
    item_name = "TestItem"
    item = Item.named_priced_with_owner_auction(item_name, initialPrice, @userA, increment, 0, nil)
    assert item.editable?
    @userB.bid(item,20)
    assert !item.editable?
  end

end