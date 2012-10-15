require 'haml'
require_relative '../models/analytics/activity_logger'

class ActivityLogger < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
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

    actor = @database.get_user_by_name(activity.actor_name)
    item = @database.get_item_by_id(activity.item_id)

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