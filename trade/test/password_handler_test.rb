require 'test/unit'
require 'require_relative'
require_relative '../app/models/security/string_checker'

class Password_Handler_Test < Test::Unit::TestCase
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
end