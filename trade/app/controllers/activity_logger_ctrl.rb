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

    activities = ActivityLogger.get_all_activities

    haml :all_activities, :locals => {
        :activities => activities
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
    Store::Purchase.dump("purchases_#{Time.now.asctime}")
    redirect back
  end

  get '/admin/transactions' do
    redirect '/login' unless @user and @user.name == 'admin'

    haml :admin_transaction_overview
  end
end