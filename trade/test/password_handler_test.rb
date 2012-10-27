require 'test/unit'
require 'require_relative'
require_relative '../app/models/security/string_checker'

class Password_Handler_Test < Test::Unit::TestCase
  include Security

  def test_length

    pw1 = "Test1"
    pw2 = "Test2test"

    assert_equal(false, Security::StringChecker.is_safe_pw?(pw1))
    assert_equal(true, Security::StringChecker.is_safe_pw?(pw2))
  end

  def test_number

    pw1 = "Testtest"
    pw2 = "Test2test"

    assert_equal(false, Security::StringChecker.is_safe_pw?(pw1))
    assert_equal(true, Security::StringChecker.is_safe_pw?(pw2))
  end

  def test_uppercase

    pw1 = "test1test"
    pw2 = "Test2test"

    assert_equal(false, Security::StringChecker.is_safe_pw?(pw1))
    assert_equal(true, Security::StringChecker.is_safe_pw?(pw2))
  end

  def test_is_nummeric
    assert(StringChecker.is_numeric?("+20"))
    assert(StringChecker.is_numeric?("-020"))
    assert(StringChecker.is_numeric?("123"))
    assert(StringChecker.is_numeric?("0123"))
    assert(!StringChecker.is_numeric?("1.2"))
    assert(!StringChecker.is_numeric?("asdf"))
    assert(!StringChecker.is_numeric?("   "))
  end

  def test_is_username
    assert(StringChecker.is_valid_username?("ese"))
    assert(!StringChecker.is_valid_username?("e se"))
    assert(!StringChecker.is_valid_username?("<script>alert()</script>"))
    assert(!StringChecker.is_valid_username?("happy-emu"))
    assert(StringChecker.is_valid_username?("happy_emu"))
    assert(!StringChecker.is_valid_username?("happy-"))
  end
end