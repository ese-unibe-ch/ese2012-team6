module Security
  class StringChecker

    #safe Password if 8 digits and at least one Number, one Capital letter

    # @param [String] password
    def self.is_safe_pw?(password)

      is_safe = false

      password_for_number =/\d+/.match(password)

      if password.size >= 8
        if password_for_number != nil
          if !password.match(password.downcase)
            is_safe=true
          end
        end
      end

      is_safe
    end

    # @param [String] string
    def self.destroy_script(string)
     string=string.gsub(/\<(\/)*[a-zA-Z]*\>/,"")
     string=remove_leading_whitespace(string)
     string
    end

    def self.remove_leading_whitespace(string)
      string=string.gsub(/\A(\s)*/,"")
      string.gsub(/(\s)*\z/,"")
    end

    def self.is_email?(email)

       /^((\w)*\.?)*\@((\w)*\.)*(\w){2,3}/.match(email)

    end
  end
end