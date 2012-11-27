require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'

class OrganizationTest < Test::Unit::TestCase
  include  Store

  def setup
    Trader.clear_all
  end

  def teardown
    Trader.clear_all
  end

  def test_check_organization_name
    name = "Umbrella Corp."
    organization = Organization.named(name)

    assert(!organization.name.nil? ,"No User Name")
    assert_equal(name, organization.name, "Wrong User name")
  end

  def test_organization_handling
    (org1 = Organization.named("me")).save
    (org2 = Organization.named("you")).save
    assert(Organization.exists?("me"), "org doesn't exist")
    assert_equal(Organization.all, [org1,org2], "organizations not in list")

    org2.delete
    assert(!Organization.exists?("you"), "org doesn't exist")
    assert(Organization.exists?("me"), "also removed org1")
  end

  def test_org_creation_with_admin
    user = User.named("admin")
    org = Organization.named("Org", :admin => user)
    assert(org.has_admin?(user))
    assert(org.has_member?(user))
  end

  def test_add_and_remove_admin
    user1 = User.named("admin")
    user2 = User.named("user")
    organization = Organization.named("new")
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
    organization = Organization.named(org_name)
    member = User.named(member_name)
    member2 = User.named("him")

    organization.add_member(member)
    assert(organization.has_member?(member), "member not in list")
    assert(organization.members.include?(member), "false member added")
    assert(!organization.members.include?(member2), "not added as member")

    organization.remove_member(member)
    assert(!organization.members.include?(member), "remove member failed")
    assert(!organization.has_member?(member), "member still in list")
  end

  def test_organization_email
    organization = Organization.named("org")
    member = User.named("you", :email => "you@mail.com")
    member2 = User.named("him", :email => "him@mail.com")

    organization.add_member(member)
    organization.add_member(member2)

    assert organization.email == ["you@mail.com","him@mail.com"]
  end

  def test_default_credits_amount
    default_amount = 0
    organization = Organization.named("Org")

    assert_equal(default_amount, organization.credits)
  end
end