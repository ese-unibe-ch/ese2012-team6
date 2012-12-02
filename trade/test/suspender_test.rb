require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/suspender'
require_relative '../app/models/store/user'

class SuspenderTest < Test::Unit::TestCase

  def setup
    Store::Suspender.suspended_users.clear
  end

  # A suspended user should be in inactive state and all its items should be deactivated
  def test_suspend_user
    user = Store::User.named("Hans")
    item = user.propose_item("Item", 20, :fixed, nil,nil)

    item.activate
    user.suspend!

    assert(Store::Suspender.suspended_users.has_key?(user.name))

    assert_equal(:suspended, user.state)
    assert_equal(:inactive, item.state)
  end

  # When user is suspended and logs back in it is no longer suspended
  def test_release_suspension
    user = Store::User.named("Hans")
    user.login

    item = user.propose_item("Item", 20, :fixed, nil,nil)
    item.activate
    user.suspend!

    assert(Store::Suspender.suspended_users.has_key?(user.name))

    assert_equal(:suspended, user.state)
    assert_equal(:inactive, item.state)

    user.login

    assert_equal(:active, user.state)
    assert_equal(:inactive, item.state)
  end
end