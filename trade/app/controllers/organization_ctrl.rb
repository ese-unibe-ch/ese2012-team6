require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')

# Handles all requests concerning user registration
class Organization < Sinatra::Application

  before do
    @user = Store::User.by_name(session[:name])
  end

  # Shows registration form
  get '/organizations' do
    redirect '/login' unless @user

    haml :all_organizations
  end

end