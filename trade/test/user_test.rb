require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/organization'
require_relative '../app/models/security/string_checker'

class UserTest < Test::Unit::TestCase
  def test_check_user_name
    name = "HansliCaramell"
    user = Store::User.named(name)

    assert(!user.name.nil? ,"No User Name")
    assert_equal(name,user.name, "Wrong User name")
  end

  def test_user_handling
    (user1 = Store::User.named("me")).save
    (user2 = Store::User.named("you")).save
    assert(Store::User.exists?(:name=>user1.name), "user doesn't exist")
    assert_equal(Store::User.all, [user1, user2], "users not in list")

    user2.delete
    assert(!Store::User.exists?(:name=>user2.name), "user doesn't exist")
    assert_equal(Store::User.by_name(user1.name), Store::User.fetch_by(:name=>user1.name), "methods are not the same")
  end

  def test_user_organization_creating
    (user = Store::User.named("me")).save
    (member = Store::User.named("you")).save
    (org1 = Store::Organization.named("org1")).save
    (org2 = Store::Organization.named("org2")).save

    org1.add_admin(user)
    assert(user.is_admin_of?(org1), "failed adding admin")
    assert(!user.is_admin_of?(org2), "admin in wrong organization")

    org1.add_member(member)
    org2.add_member(member)
    assert(member.is_member_of?(org1), "failed adding member")
    assert_equal(member.organizations, [org1, org2], "is in wrong organization")
  end

  def test_work_as
    (user = Store::User.named("user")).save
    (org = Store::Organization.named("org")).save

    assert(user.working_as_self?, "is not working on behalf of himself")
    assert(!user.working_on_behalf_of?(org), "is working on behalf of this org")

    user.work_on_behalf_of(org)
    assert(user.working_on_behalf_of?(org), "is not working on behalf of this org")
    assert(!user.working_as_self?, "is still working on behalf of himself")
  end

  def test_password_matches_default_password
    user = Store::User.named("user")
    assert(!user.password_matches?("blabla"))
    assert(user.password_matches?("user"))
  end

  def test_password_matches_custom_password
    user = Store::User.named("user", :password => "verysecret")
    assert(!user.password_matches?("user"))
    assert(user.password_matches?("verysecret"))
  end

  def test_change_password
    user = Store::User.named("user")
    assert(user.password_matches?("user"))

    user.change_password("newpass")
    assert(!user.password_matches?("user"))
    assert(user.password_matches?("newpass"))
  end

  def test_reset_password
    user = Store::User.named("user")
    assert(user.password_matches?("user"))

    user.reset_password(false)
    assert(!user.password_matches?("user"))
  end
end