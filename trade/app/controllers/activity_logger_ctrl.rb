require 'haml'
require_relative '../models/analytics/activity_logger'

class ActivityLogger < Sinatra::Application
  include Store
  include Analytics

  before do
    @user = User.by_name(session[:name])
  end

  # show list of all stored activities
  get '/activities' do
    redirect '/login' unless @user

    activities = ActivityLogger.get_all_activities

    haml :all_activities, :locals => {
        :activities => activities
    }
  end

  # show details page of an activity, not yet used!
  get "/activity/:act_id" do
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
end