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
<<<<<<< HEAD
    name = (params[:username])
    redirect '/error/user_no_exists' unless User.exists?(:name => name)

    if name == "admin" || name == "ese" || name == "ese2" || name == "petergriffin" || name == "umbrellacorp"
      redirect '/error/trying forget pd for pre saved users'
    end
=======
    name = params[:username]

    redirect '/error/trying forget pd for pre saved users' if ["admin", "umbrellacorp", "ese", "ese2", "petergriffin"].include?(name)
    redirect '/error/user_no_exists' unless User.exists?(:name => name)

    user = Store::User.by_name(name)
    user.reset_password
>>>>>>> 58116885c1f711ec6d3941d825207183936b5860

    user = Store::User.by_name(name)
    redirect back if user.nil?

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
