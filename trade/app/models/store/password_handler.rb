module Store
  class Password_Handler


    #safe Password if 8 digits and at least one Number, one Capital letter


    # @param [String] password
    def is_safe_pw?(password)

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
  end
end