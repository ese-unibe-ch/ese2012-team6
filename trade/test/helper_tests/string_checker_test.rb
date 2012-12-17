require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../../app/models/helpers/security/string_checker'

class StringCheckerTest < Test::Unit::TestCase
  include Security

  # tests the length for password creation
  def test_length
    pw1 = "Test1"
    pw2 = "Test2test"

    assert_equal(false, StringChecker.is_safe_pw?(pw1))  # to short, min 8 character inputs
    assert_equal(true, StringChecker.is_safe_pw?(pw2))
  end

  # the password must contain at least one number
  def test_number

    pw1 = "Testtest"
    pw2 = "Test2test"

    assert_equal(false, StringChecker.is_safe_pw?(pw1))
    assert_equal(true, StringChecker.is_safe_pw?(pw2))
  end

  # the password must contain at least one upper case letter
  def test_uppercase

    pw1 = "test1test"
    pw2 = "Test2test"

    assert_equal(false, StringChecker.is_safe_pw?(pw1))
    assert_equal(true, StringChecker.is_safe_pw?(pw2))
  end

  # tests acceptance of numbers, for example the item price
  def test_is_nummeric
    assert(StringChecker.is_numeric?("+20"))
    assert(StringChecker.is_numeric?("-020"))
    assert(StringChecker.is_numeric?("123"))
    assert(StringChecker.is_numeric?("0123"))
    assert(!StringChecker.is_numeric?("1.2"))
    assert(!StringChecker.is_numeric?("asdf"))
    assert(!StringChecker.is_numeric?("   "))
  end

  # a user name can not contain white spaces or non-alphabetic characters
  def test_is_username
    assert(StringChecker.is_valid_username?("ese"))
    assert(!StringChecker.is_valid_username?("e se"))
    assert(!StringChecker.is_valid_username?("<script>alert()</script>"))
    assert(!StringChecker.is_valid_username?("happy-emu"))
    assert(StringChecker.is_valid_username?("happy_emu"))
    assert(!StringChecker.is_valid_username?("happy-"))
  end

  # scripts are not accepted in all string inputs
  def test_destroy_script
    string = "<script>alert()</script>"
    destroyed = StringChecker.remove_script_tags(string)
    assert(!destroyed.include?("<script>"))
    assert(!destroyed.include?("</script>"))
  end

  # tests the correctness of an email-address
  def test_is_email
    assert(StringChecker.is_email?("happy@email.com"))
    assert(StringChecker.is_email?("happy.emu@email.com"))
    assert(!StringChecker.is_email?("@email.com"))
    assert(!StringChecker.is_email?("happy@com"))
    assert(!StringChecker.is_email?("happy-.,.@email.com"))
    assert(StringChecker.is_email?("happy@student.email.com"))
    assert(!StringChecker.is_email?(""))
  end
end