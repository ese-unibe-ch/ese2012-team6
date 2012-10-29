require 'test/unit'
require 'require_relative'
require_relative('../../trade/app/models/security/Mail_Client')

class Mail_Client_Test  < Test::Unit::TestCase

  def test_send_mail

    Security::Mail_client.send_mail('jonas.vonfelten@students.unibe.ch','aöhdf454')
  end


end

