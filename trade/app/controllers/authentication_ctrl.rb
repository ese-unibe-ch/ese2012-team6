require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

# Handles all requests concerning User Authentication, namely Login and Logout
class Authentication < Sinatra::Application

  before do
    @user = Store::User.by_name(session[:name])
  end

  # GET handler for login request, shows login form
  get "/login" do
    redirect '/' if @user

    haml :login
  end

  post "/login/passwordReset/"do
    name = (params[:username])
    puts name


    user= Store::User.by_name(name)

    if user ==nil
      redirect back
    end

    user.reset_password;

    redirect back
  end

  # POST handler for login request, processes input and logs user in if possible
  post "/login" do
    name = Security::StringChecker.destroy_script(params[:username])
    password = params[:password].gsub(/\s+/, "") #remove all whitespaces

    redirect '/error/login_no_pwd_user' if name.nil? or password.nil? or name == "" or password == ""
    redirect '/error/user_no_exists' unless Store::User.exists?(name)

    user = Store::User.by_name(name)
    redirect '/error/wrong_password' unless user.password_matches?(password)

    session[:name] = name
    user.login

    redirect '/'
  end

  # GET handler for logout request, logs out the user
  # UG: TODO: Should be POST
  get "/logout" do
    redirect '/' unless @user

    @user.logout
    @user = nil
    session[:name] = nil

    redirect '/login'
  end
end
