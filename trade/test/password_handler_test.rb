require 'test/unit'
require '../app/models/store/password_handler'
require '../../trade/app/models/store/user'
require '../../trade/app/models/store/item'


class Password_Handler_Test < Test::Unit::TestCase
  def test_length
    puts "hello"
    pw1 = "Test1"
    pw2 = "Test2test"
    pw_handler = Store::Password_Handler.new
    assert_equal(false, pw_handler.is_safe_pw?(pw1))
    assert_equal(true, pw_handler.is_safe_pw?(pw2))
  end

  def test_number
    puts "hello"
    pw1 = "Testtest"
    pw2 = "Test2test"
    pw_handler = Store::Password_Handler.new
    assert_equal(false, pw_handler.is_safe_pw?(pw1))
    assert_equal(true, pw_handler.is_safe_pw?(pw2))
  end

  def test_uppercase
    puts "hello"
    pw1 = "test1test"
    pw2 = "Test2test"
    pw_handler = Store::Password_Handler.new
    assert_equal(false, pw_handler.is_safe_pw?(pw1))
    assert_equal(true, pw_handler.is_safe_pw?(pw2))
  end
end