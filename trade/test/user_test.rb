require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'

class UserTest < Test::Unit::TestCase
  include Store

  def setup
    Trader.clear_all
  end

  def teardown
    Trader.clear_all
  end

  def test_check_user_name
    user = User.named("HansliCaramell")

    assert(!user.name.nil? ,"No User Name")
    assert_equal("HansliCaramell", user.name, "Wrong User name")
  end

  # tests the existence of a created user and the existence after deletion
  def test_user_handling
    (user1 = User.named("me")).save
    (user2 = User.named("you")).save

    assert(User.exists?(user1.name), "user doesn't exist")
    assert_equal(User.all, [user1, user2], "users not in list")

    user2.delete
    assert(!User.exists?("you"), "user doesn't exist")
  end

  def test_user_organization_creating
    user = User.named("me")
    member = User.named("you")
    org1 = Organization.named("org1")
    org2 = Organization.named("org2")

    org1.add_admin(user)

    assert(user.is_admin_of?(org1), "failed adding admin")
    assert(!user.is_admin_of?(org2), "admin in wrong organization")

    org1.add_member(member)
    org2.add_member(member)

    assert(member.is_member_of?(org1), "failed adding member")
    assert_equal(member.organizations, [org1, org2], "is in wrong organization")
  end

  # tests functionality of changing the mode of working as self or as organization
  def test_work_as
    (user = User.named("user")).save
    (org = Organization.named("org")).save

    assert(user.working_as_self?, "is not working on behalf of himself")
    assert(!user.working_on_behalf_of?(org), "is working on behalf of this org")

    user.work_on_behalf_of(org)
    assert(user.working_on_behalf_of?(org), "is not working on behalf of this org")
    assert(!user.working_as_self?, "is still working on behalf of himself")
  end

  # tests whether a member of an organization can edit an item
  def test_can_edit_org_item
    user = User.named("user")
    org = Organization.named("org")

    item = org.propose_item("Item", 20, :fixed, nil, nil)
    assert(!user.can_edit?(item))

    user.work_on_behalf_of(org)
    assert(user.on_behalf_of.can_edit?(item))
  end

  # tests whether a member of an org can buy it's item
  def test_can_buy_org_item
    user = User.named("user")
    org = Organization.named("org")

    item = org.propose_item("Item", 20, :fixed, nil, nil)
    item.activate

    assert(user.can_buy?(item))

    user.work_on_behalf_of(org)
    assert(!user.on_behalf_of.can_buy?(item))
  end

  def test_password_matches_default_password
    user = User.named("user")
    assert(!user.password_matches?("blabla"))
    assert(user.password_matches?("user"))
  end

  def test_password_matches_custom_password
    user = User.named("user", :password => "verysecret")
    assert(!user.password_matches?("user"))
    assert(user.password_matches?("verysecret"))
  end

  def test_change_password
    user = User.named("user")
    assert(user.password_matches?("user"))

    user.change_password("newpass")
    assert(!user.password_matches?("user"))
    assert(user.password_matches?("newpass"))
  end

  def test_reset_password
    user = User.named("user")
    assert(user.password_matches?("user"))

    new_password = user.reset_password(false)
    assert(!user.password_matches?("user"))
    assert(user.password_matches?(new_password))
  end
end