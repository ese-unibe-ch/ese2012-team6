require 'require_relative'
require 'tilt/haml'

require_relative '../models/trade/user'


class Authentication < Sinatra::Application


  post "/register" do
      username = params[:username]
      if Trade::User.all.detect {|user| user.name == username} != nil
        redirect "/registration_failed"
      else
        Trade::User.named(username).save
      end
      redirect "/registration_succeeded"
  end


  get "/registration_failed" do
    haml :registration_failed
  end


  get "/registration_succeeded" do
    haml :registration_success
  end


  get "/login" do
    haml :login
  end


  post "/login" do
    name = params[:username]
    password = params[:password]

    if name.nil? or password.nil?
      redirect '/login'
    end

    user = Trade::User.by_name(name)

    if user.nil? or password != name
      redirect '/login'
    end

    session[:name] = name
    redirect '/'
  end


  get "/logout" do
    session[:name] = nil
    redirect '/login'
  end

end