require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/trader'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/trading_authority'

class TradingAuthorityTest < Test::Unit::TestCase
  include Store

  def test_creation
    TradingAuthority.timed(3)
    assert_equal(3, TradingAuthority.credit_reduce_time)
    assert_equal(nil, TradingAuthority.reduce_thread)
    TradingAuthority.stop
  end

  # tests the functionality of stopping and starting the Trading Authority
  def test_start
    TradingAuthority.timed(3)
    TradingAuthority.start

    assert_equal(true, TradingAuthority.reduce_thread.alive?)

    TradingAuthority.stop

    assert_equal(false, TradingAuthority.reduce_thread.alive?)
  end

  # tests the reduce of credits by 1% for user and organization
  def test_reduce_credits
    user = User.named("User", :credits => 100)
    org = Organization.named("Org", :credits => 100)

    user.save
    org.save

    TradingAuthority.reduce_all_user_credits

    assert_equal(100-Integer(100*TradingAuthority.credit_reduce_rate*0.01), user.credits)
    assert_equal(100-Integer(100*TradingAuthority.credit_reduce_rate*0.01), org.credits)
  end

  # time dependent unit test, result dependent on machine
=begin
  def test_reduce_credits_timed
    user = User.named("User", :credits => 100)
    org = Organization.named("Org", :credits => 100)

    user.save
    org.save

    TradingAuthority.timed(1)

    TradingAuthority.start

    sleep 1.5

    assert_equal(100-Integer(100*TradingAuthority.credit_reduce_rate*0.01), user.credits)
    assert_equal(100-Integer(100*TradingAuthority.credit_reduce_rate*0.01), org.credits)

    TradingAuthority.stop
  end
=end
end