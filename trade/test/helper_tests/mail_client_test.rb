require 'rubygems'
require 'test/unit'
require 'require_relative'
require_relative '../../app/models/helpers/security/mail_client'

class MailClientTest < Test::Unit::TestCase
  def test_send_mail
    #Security::MailClient.send_mail('awesome.trading.app@gmail.com','aöhdf454')
  end
end

