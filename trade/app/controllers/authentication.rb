require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

# Handles all requests concerning User Authentication, namely Login and Logout
class Authentication < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  # GET handler for login request, shows login form
  get "/login" do
    redirect '/' if session[:name]

    haml :login
  end

  # POST handler for login request, processes input and logs user in if possible
  post "/login" do
    name =Security::String_Manager::destroy_script(params[:username])
    password = params[:password]

    redirect '/error/login_no_pwd_user' if name.nil? or password.nil? or name == "" or password == ""

    redirect '/error/user_no_exists' unless @database.user_exists?(name)

    user = @database.get_user_by_name(name)
    redirect '/error/wrong_password' unless user.password_matches?(password)

    redirect '/login' unless @database.get_user_by_name(name).password_matches?(password)

    session[:name] = name

    redirect '/'
  end

  # GET handler for logout request, logs out the user
  get "/logout" do
    session[:name] = nil
    redirect '/login'
  end

end
