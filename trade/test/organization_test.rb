require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'

class OrganizationTest < Test::Unit::TestCase
  include  Store

  def setup
    SystemUser.clear_all
  end

  def teardown
    SystemUser.clear_all
  end

  def test_check_organization_name
    name = "Umbrella Corp."
    organization = Store::Organization.named(name)

    assert(!organization.name.nil? ,"No User Name")
    assert_equal(name,organization.name, "Wrong User name")
  end

  def test_organization_handling
    (org1 = Store::Organization.named("me")).save
    (org2 = Store::Organization.named("you")).save
    assert(Store::Organization.exists?(:name=>org1.name), "org doesn't exist")
    assert_equal(Store::Organization.all, [org1,org2], "organizations not in list")

    org2.delete
    assert(!Store::Organization.exists?(:name=>org2.name), "org doesn't exist")
    assert(Store::Organization.fetch_by(:id=>org1.id), "also removed org1")
  end

  def test_org_creation_with_admin
    user = Store::User.named("admin")
    org = Store::Organization.named("Org", :admin => user)
    assert(org.has_admin?(user))
    assert(org.has_member?(user))
  end

  def test_add_and_remove_admin
    user1 = Store::User.named("admin")
    user2 = Store::User.named("user")
    organization = Store::Organization.named("new")
    organization.add_admin(user1)
    assert(organization.has_admin?(user1), "failed adding admin")
    assert(!organization.has_admin?(user2), "wrong admin added")

    organization.add_admin(user2)
    organization.remove_admin(user1)
    assert(!organization.has_admin?(user1), "user is still admin")
    assert(organization.admins.include?(user2), "wrong user as admin")
  end

  def test_add_and_remove_member
    org_name = "org"
    member_name = "you"
    organization = Store::Organization.named(org_name)
    member = Store::User.named(member_name)
    member2 = Store::User.named("him")

    organization.add_member(member)
    assert(organization.has_member?(member), "member not in list")
    assert(organization.members.include?(member), "false member added")
    assert(!organization.members.include?(member2), "not added as member")

    organization.remove_member(member)
    assert(!organization.members.include?(member), "remove member failed")
    assert(!organization.has_member?(member), "member still in list")
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
end