require 'rubygems'
require 'tlsmail'

module Security
  # provides service to send mails to recipients
  class MailDispatcher
    # send a mail with content to recipient
    def self.send_password_mail(to, contents)

      from = 'awesome.trading.app@gmail.com' #insert a gmail address
      pw = 'our_app_is_awesome' #and the password to the corresponding account

      content = <<EOF
From: #{from}
To: #{to}
subject: Password Reset


      Your Password has been reset on request to "#{contents}"
      Please change it immediately after your next login.

Sincerely,
Awesome Trading App
EOF

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
        smtp.send_message(content, from, to)
      end
    end

    def self.send_new_winner_mail(to, item)
      from = 'awesome.trading.app@gmail.com' #insert a gmail address
      pw = 'our_app_is_awesome' #and the password to the corresponding account

      content = <<EOF
From: #{from}
To: #{to}
subject: New leader in auction


      There is a new leader in the auction for #{item.name}. Bid higher if
      you want to become leader again.

Sincerely,
Awesome Trading App
EOF

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
        to.each {|recipient|
          smtp.send_message content, from, recipient unless [nil, ""].include?(recipient)
        }
      end
    end

    def self.send_notice_seller_mail(to, buyer_name, buyer_email, item)  #to = seller.email
      from = 'awesome.trading.app@gmail.com' #insert a gmail address
      pw = 'our_app_is_awesome' #and the password to the corresponding account

      content = <<EOF
From: #{from}
To: #{to}
subject: Your #{item.name} has been sold

      The following item has been sold: #{item.name}
      Contact information:
      Name of buyer: #{buyer_name}
      Email of buyer: #{buyer_email}

Sincerely,
Awesome Trading App
EOF

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
        to.each {|recipient|
          smtp.send_message content, from, recipient unless [nil, ""].include?(recipient)
        }
      end
    end
  end
end



