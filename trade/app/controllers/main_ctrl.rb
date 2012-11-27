require 'haml'
require_relative('../models/store/user')
require_relative('../models/store/item')
require_relative('../models/helpers/exceptions/exception_text')

# Handles all requests concerning item store and error display
class Main < Sinatra::Application
  include Store
  include Analytics

  before do
    @user = User.by_name(session[:name])
  end

  # Default page handler, shows store page
  get '/' do
    redirect '/login' unless @user

    @user.on_behalf_of.acknowledge_item_properties!

    most_recent_purchases = ActivityLogger.get_most_recent_purchases(10)

    haml :store, :locals => { :users => Store::User.all_active,
                              :most_recent_purchases => most_recent_purchases
    }
  end

  # Error handler, shows error message
  get '/error/:error_msg' do

    should_refresh = false

    case params[:error_msg]
      when "not_owner_of_item"
        should_refresh = true
      when "item_changed_details"
        should_refresh = true
      when "NOT_ENOUGH_CREDITS"
        should_refresh = true
      when "BUY_INACTIVE_ITEM"
        should_refresh = true
      when "user_credit_transfer_failed"
        should_refresh = true
      when "organization_credit_transfer_failed"
        should_refresh = true
<<<<<<< HEAD
      when "wrong_transfer_amount"
        error_message = "You must transfer a positive integral amount of credits"
      when "invalid_username"
        error_message = "Your user name must only contain word characters (lower/uppercase letters and underscores)"
      when "trying forget pd for pre saved users"
        error_message = "This user was created for fast program testing, thus it hasn't got an email address"
      when "delete_failed"
        error_message = "You cannot delete your account because you have active auctions"
=======
>>>>>>> 87c57e2ccfc98b828ace71ee747cc04d0ceb7512
    end

    error_message = Exceptions::ExceptionText.get(params[:error_msg])

    last_page = back

    haml :error, :locals => { :error_message => error_message,
                              :last_page => last_page,
                              :should_refresh => should_refresh
    }
  end
end