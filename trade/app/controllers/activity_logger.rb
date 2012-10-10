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

  get '/activity/:act_id' do
    redirect '/login' unless @user
    activity = Analytics::ActivityLogger.by_id(act_id)

    haml :activity, :locals => {
        :activity => activity
    }
  end
end