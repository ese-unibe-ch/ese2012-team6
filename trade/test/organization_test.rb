require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_check_organization_name
    name = "Umbrella Corp."
    organization = Store::Organization.named(name)

    assert(!organization.name.nil? ,"No User Name")
    assert_equal(name,organization.name, "Wrong User name")
  end

  def test_default_credits_amount
    default_amount = 0
    organization = Store::Organization.new

    assert(organization.credits == default_amount)
  end

  def test_custom_credits_amount
    amount = 123
    organization = Store::Organization.new
    organization.credits = amount

    assert(organization.credits == amount)
  end

  # Only add tests that really test functionality of Oranization, not SystemUser!
end