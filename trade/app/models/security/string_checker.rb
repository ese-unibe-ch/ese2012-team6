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
     string = string.strip
     string = string.gsub(/\<(\/)*[a-zA-Z]*\>/,"")
     string
    end

    def self.is_numeric?(string)
      return self.matches_regex?(string, /^[+-]?\d+/)
    end

    def self.is_valid_username?(string)
      return self.matches_regex?(string, /\w+/)
    end

    def self.matches_regex?(string, regex)
      return ((string.scan(regex))[0] == string)
    end
  end
end