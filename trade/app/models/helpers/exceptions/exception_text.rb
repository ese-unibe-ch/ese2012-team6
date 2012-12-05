module Exceptions
  class ExceptionText
    class << self
      def get(error_code)
        case error_code
          when "not_owner_of_item"
            error_message = "Item does not belong to you anymore"
          when "item_changed_details"
            error_message = "Trying to buy inactive item or the owner changed some details"
          when "ITEM_NO_OWNER"
            error_message = "Item does not belong to anybody"
          when "NOT_ENOUGH_CREDITS"
            error_message = "Buyer does not have enough credits"
          when "BUY_INACTIVE_ITEM"
            error_message = "Trying to buy inactive item"
          when "SELLER_NOT_ITEM_OWNER"
            error_message = "Seller does not own item to buy"
          when "user_no_exists"
            error_message = "User is not registered in the system"
          when "login_no_pwd_user"
            error_message = "Empty username or password"
          when "user_already_exists"
            error_message = "Username already exists! Please choose another one"
          when "pwd_rep_no_match"
            error_message = "Passwords do not match. Please try again"
          when "no_user_name"
            error_message = "You must choose a user name"
          when "no_email"
            error_message = "You must enter a valid e-mail address"
          when "pwd_unsafe"
            error_message = "Your password is unsafe. It must be at least 8 characters long and contain
                      at least one upper case letter and at least one number"
          when "invalid_price"
            error_message = "You entered an invalid price. Please enter a positive numeric value"
          when "INVALID_QUANTITY"
            error_message = "You entered an invalid quantity"
          when "wrong_password"
            error_message = "You entered a wrong password"
          when "wrong_size"
            error_message = "Please choose a picture with the maximum size of 400kB"
          when "no_name"
            error_message = "Type a name for your Organization"
          when "user_credit_transfer_failed"
            error_message = "You do not have enough credits to transfer"
          when "organization_credit_transfer_failed"
            error_message = "Organization does not have enough credits to transfer"
          when "wrong_transfer_amount"
            error_message = "You must transfer a positive integral amount of credits"
          when "invalid_username"
            error_message = "Your user name must only contain word characters (lower/uppercase letters and underscores)"
          when "trying forget pd for pre saved users"
            error_message = "This user was created for fast program testing, thus it hasn't got an email address"
          when "delete_failed"
            error_message = "You cannot delete your account because you have active auctions"
          when "invalid_admin_input"
            error_message = "Your input is invalid"
          else
            error_message = "Unknown error"
        end
        error_message
      end
    end
end

end