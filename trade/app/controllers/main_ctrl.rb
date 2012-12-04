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

    haml :item_store, :locals => { :users => Store::User.all_active,
                              :most_recent_purchases => most_recent_purchases
    }
  end

  get '/store/item' do
    redirect '/login' unless @user

    @user.on_behalf_of.acknowledge_item_properties!

    most_recent_purchases = ActivityLogger.get_most_recent_purchases(10)

    haml :item_store, :locals => { :users => Store::User.all_active,
                                   :most_recent_purchases => most_recent_purchases
    }
  end

  get '/store/auction' do
    redirect '/login' unless @user

    @user.on_behalf_of.acknowledge_item_properties!

    most_recent_purchases = ActivityLogger.get_most_recent_purchases(10)

    haml :auction_store, :locals => { :users => Store::User.all_active,
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
      when "INVALID_BID"
        should_refresh = true
      when "user_credit_transfer_failed"
        should_refresh = true
      when "organization_credit_transfer_failed"
        should_refresh = true
    end

    error_message = Exceptions::ExceptionText.get(params[:error_msg])

    last_page = back

    haml :error, :locals => { :error_message => error_message,
                              :last_page => last_page,
                              :should_refresh => should_refresh
    }
  end
end