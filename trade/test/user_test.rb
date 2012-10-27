require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_check_user_name
    name = "HansliCaramell"
    user = Store::User.named(name)

    assert(!user.name.nil? ,"No User Name")
    assert_equal(name,user.name, "Wrong User name")
  end

  def test_default_credits_amount
    default_amount = 100
    user = Store::User.new

    assert_equal(default_amount, user.credits)
  end

  def test_custom_credits_amount
    amount = 123
    user = Store::User.new
    user.credits = amount

    assert_equal(amount, user.credits)
  end

  # Only add tests that really test functionality of User, not SystemUser!
end