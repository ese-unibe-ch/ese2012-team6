require 'haml'
require_relative('../models/store/user')

# Handles all requests concerning User Authentication, namely Login and Logout
class Authentication < Sinatra::Application
  include Store
  include Security

  before do
    @user = User.by_name(session[:name])
  end

  # GET handler for login request, shows login form
  get "/login" do
    redirect '/' if @user

    haml :login
  end

  # handle user change password request
  post "/login/passwordReset/"do
    name = (params[:username])

    redirect '/error/user_no_exists' unless User.exists?(:name => name)

    user = Store::User.by_name(name)

    redirect back if user.nil?
    if user == "admin" || "umbrellacorp" || "ese" || "ese2" || "petergriffin"
      redirect '/error/trying forget pd for pre saved users'
    end
    user.reset_password

    redirect back
  end

  # POST handler for login request, processes input and logs user in if possible
  post "/login" do
    name = params[:username].strip
    password = params[:password].strip

    redirect '/error/user_no_exists' unless User.exists?(:name => name)

    user = User.by_name(name)
    redirect '/error/wrong_password' unless user.password_matches?(password)

    session[:name] = name
    user.login
    @user = user

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
