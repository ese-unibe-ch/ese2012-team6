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
    assert(item.currentSellingPrice == nil) #there is no lowest-Bid, therefore no price to pay

    assert(@userB.canBid?(item,10))

    @userB.bid(item,10)
    assert(item.currentSellingPrice == initialPrice) #userB would pay initial price, since he is the first bidder

    assert(!@userC.canBid?(item,initialPrice))    #shown price = 5, can bid from 5+inc
    assert(!@userC.canBid?(item,initialPrice+1))
    assert(@userC.canBid?(item,initialPrice+increment))
    @userC.bid(item,initialPrice+increment)
    print item.currentSellingPrice
    assert(item.currentSellingPrice == 9)               #price should be 5 + inc (= bid) + inc (for the winner)

    assert(!@userC.canBid?(item,7))    #shown price = 7, can bid from 7+inc
    assert(!@userC.canBid?(item,8))
    assert(@userC.canBid?(item,9))
    @userC.bid(item,9)
    assert(item.currentSellingPrice == 9)

  end

end