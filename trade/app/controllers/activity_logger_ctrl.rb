require 'haml'
require_relative '../models/analytics/activity_logger'

class ActivityLogger < Sinatra::Application

  before do
    @user = Store::User.by_id(session[:name])
  end

  get '/activities' do
    redirect '/login' unless @user

    activities = Analytics::ActivityLogger.get_all_activities

    haml :all_activities, :locals => {
        :activities => activities
    }
  end

  get "/activity/:act_id" do
    redirect '/login' unless @user

    activity_id = params[:act_id]
    activity = Analytics::ActivityLogger.by_id(Integer(activity_id))

    actor = Store::User.by_id(activity.actor_name)
    item = Store::Item.by_id(activity.item_id)

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