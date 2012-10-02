require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

class Authentication < Sinatra::Application

  get "/login" do
    redirect '/' if session[:name]

    haml :login
  end

  post "/login" do
    name = params[:username]
    password = params[:password]

    fail "Empty username or password" if name.nil? or password.nil?

    redirect '/error/user_no_exists' unless App.user_exist?(name)
    redirect '/login' unless name == password and App.user_exist?(name)

    session[:name] = name
    redirect '/'
  end

  get "/logout" do
    session[:name] = nil
    redirect '/login'
  end

end