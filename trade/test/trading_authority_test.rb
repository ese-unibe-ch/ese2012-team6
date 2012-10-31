require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/system_user'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/trading_authority'

class TradingAuthorityTest < Test::Unit::TestCase
  include Store

  def test_creation_default_timeout
    ta = TradingAuthority.new
    assert_equal(24*60*60, ta.credit_reduce_time)
    assert_equal(nil, ta.reduce_thread)
    ta.stop
  end

  def test_creation
    ta = TradingAuthority.timed(3)
    assert_equal(3, ta.credit_reduce_time)
    assert_equal(nil, ta.reduce_thread)
    ta.stop
  end

  def test_start
    ta = TradingAuthority.timed(3)
    ta.start

    assert_equal(true, ta.reduce_thread.alive?)

    ta.stop

    assert_equal(false, ta.reduce_thread.alive?)
  end

  def test_reduce_credits
    user = User.named("User", :credits => 100)
    org = Organization.named("Org", :credits => 100)

    user.save
    org.save

    TradingAuthority.swing_hammer_of_doom

    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), user.credits)
    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), org.credits)
  end

  def test_settle_purchase
    seller = User.named("seller", :credits => 100)
    buyer = User.named("buyer", :credits => 100)

    item = seller.propose_item("item", 50)
    TradingAuthority.settle_item_purchase(seller, buyer, item)

    assert_equal(153, seller.credits)
    assert_equal(50, buyer.credits)
  end

  # time dependent unit test, result dependent on machine
=begin
  def test_reduce_credits_timed
    user = User.named("User", :credits => 100)
    org = Organization.named("Org", :credits => 100)

    user.save
    org.save

    ta = TradingAuthority.timed(1)

    ta.start

    sleep 1.5

    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), user.credits)
    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), org.credits)

    ta.stop
  end
=end
end