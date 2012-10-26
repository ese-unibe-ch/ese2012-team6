require 'haml'
require_relative('../models/store/user')
require_relative('../models/store/item')

class Main < Sinatra::Application

  before do
    @user = Store::User.by_name(session[:name])
  end

  # Default page handler, shows store page
  get "/" do
    redirect '/login' unless @user

    @user.open_item_page_time = Time.now

    most_recent_purchases = Analytics::ActivityLogger.get_most_recent_purchases(10)

    haml :store, :locals => { :users => Store::User.all,
                              :most_recent_purchases => most_recent_purchases
    }
  end

  # Error handler, shows error message
  get "/error/:error_msg" do

    should_refresh = false

    case params[:error_msg]
      when "not_owner_of_item"
        error_message = "Item does not belong to you anymore"
        should_refresh = true
      when "item_changed_details"
        error_message = "Trying to buy inactive item or the owner changed some details"
        should_refresh = true
      when "item_no_owner"
        error_message = "Item does not belong to anybody"
      when "not_enough_credits"
        error_message = "Buyer does not have enough credits"
      when "buy_inactive_item"
        error_message = "Trying to buy inactive item"
      when "seller_not_own_item"
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
    end

    last_page = back

    haml :error, :locals => { :error_message => error_message,
                              :last_page => last_page,
                              :should_refresh => should_refresh
    }
  end
end