module Security
  # provides services for checking string properties
  class StringChecker

    # test whether a password string is considered safe
    # safe Password if 8 digits and at least one Number, one Capital letter
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

    # destroy script tags within a string
    def self.destroy_script(string)
     string = string.strip
     string = string.gsub(/\<(\/)*[a-zA-Z]*\>/,"")
     string
    end

    # test whether a string can be converted into an integral numeric value
    def self.is_numeric?(string)
      return self.matches_regex?(string, /^[+-]?\d+/)
    end

    # test whether string is a valid user name, thus containing only word characters and underscores
    def self.is_valid_username?(string)
      return self.matches_regex?(string, /\w+/)
    end

    # test whether string matches certain regex
    def self.matches_regex?(string, regex)
      match = regex.match(string)
      return false unless match
      return (match[0] == string) unless match.nil?
    end

    # test whether string is a valid email address
    def self.is_email?(email)
      return self.matches_regex?(email, /^[\w*\.?]+@(\w*\.)+\w{2,3}\z/ )
    end
  end
end