require 'haml'
require_relative '../models/analytics/activity_logger'
require_relative '../models/store/user'
require_relative '../models/store/item'
require_relative '../models/store/purchase'

# handles requests concerning activities and activity logging
class ActivityLogger < Sinatra::Application
  include Store
  include Analytics

  before do
    @user = User.by_name(session[:name])
  end

  # show list of all stored activities
  get '/activities' do
    redirect '/login' unless @user and @user.name=='admin'

    filters = params[:filters] ? params[:filters] : []
    filters.each_index {|idx| filters[idx] = filters[idx].to_sym}

    activities = ActivityLogger.get_activities(filters)

    haml :all_activities, :locals => {
        :activities => activities,
        :active_filters => filters
    }
  end

  # show details page of an activity, not yet used!
  get '/activity/:act_id' do
    redirect '/login' unless @user

    activity_id = params[:act_id]
    activity = ActivityLogger.by_id(Integer(activity_id))

    actor = User.by_id(activity.actor_name)
    item = Item.by_id(activity.item_id)

    actor_still_in_system = !actor.nil?
    item_still_in_system = !item.nil?

    haml :activity, :locals => {
        :activity => activity,
        :actor => actor,
        :item => item,
        :actor_still_in_system => actor_still_in_system,
        :item_still_in_system => item_still_in_system
    }
  end

  post '/purchases/dump' do
    redirect '/login' unless @user
    Store::Purchase.dump("purchases_#{Time.now.asctime}.csv".gsub(" ", "_"))
    redirect back
  end

  get '/admin/transactions' do
    redirect '/login' unless @user and @user.name == 'admin'

    purchases = Store::Purchase.get_purchases_of_last '24h'
    transaction_count, total_credits = ActivityLogger.get_transaction_statistics_of_last '24h'

    haml :admin_transaction_overview, :locals => {
        :transaction_count => transaction_count,
        :total_credits => total_credits,
        :purchases => purchases
    }
  end
end