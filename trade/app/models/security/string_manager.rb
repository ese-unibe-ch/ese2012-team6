module Security
  class String_Manager


    #safe Password if 8 digits and at least one Number, one Capital letter


    # @param [String] password
    def String_Manager::is_safe_pw?(password)

      is_safe = false

      password_for_number =/\d+/.match(password)


      if password.size >=8
        if password_for_number != nil
          if !password.match(password.downcase)
            is_safe=true
          end
        end
      end


      is_safe
    end

    # @param [String] string
    def String_Manager::destroy_script(string)
     string=string.gsub(/\W/,"")
     string=remove_leading_whitespace(string)
     string
    end

    def String_Manager::remove_leading_whitespace(string)
      string=string.gsub(/\A(\s)*/,"")
      string.gsub(/(\s)*\z/,"")
    end
  end
end