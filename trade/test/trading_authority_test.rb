require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/system_user'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/trading_authority'

class SystemUserTest < Test::Unit::TestCase
  include Store

  def test_creation
    ta = TradingAuthority.timed(3)

    assert_equal(3, ta.credit_reduce_time)
    assert_equal(nil, ta.reduce_thread)
  end

  def test_start
    ta = TradingAuthority.timed(3)
    ta.start

    assert_equal(true, ta.reduce_thread.alive?)

    ta.reduce_thread.kill
  end

  def test_reduce_credits
    user = User.named("User", :credits => 100)
    org = Organization.named("Org", :credits => 100)

    user.save
    org.save

    ta = TradingAuthority.timed(3)

    ta.swing_hammer_of_doom

    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), user.credits)
    assert_equal(100-Integer(100*TradingAuthority::CREDIT_REDUCE_RATE), org.credits)
  end

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

    ta.reduce_thread.kill
  end
end