require 'haml'
require 'models/store/item'
require 'models/store/user'

class Authentication < Sinatra::Application

  get "/login" do
    haml :login
  end

  post "/login" do
    name = params[:username]
    password = params[:password]

    fail "Empty username or password" if name.nil? or password.nil?
    fail "User does not exist" unless App.user_exist?()
    redirect '/login' if name != password

    session[:name] = name
    redirect '/'
  end

  get "/logout" do
    session[:name] = nil
    redirect '/login'
  end

end