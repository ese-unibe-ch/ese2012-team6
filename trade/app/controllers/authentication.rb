require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

class Authentication < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  get "/login" do
    redirect '/' if session[:name]

    haml :login
  end

  post "/login" do
    name = params[:username]
    password = params[:password]

    redirect '/error/login_no_pwd_user' if name.nil? or password.nil? or name == "" or password == ""
    redirect '/error/user_no_exists' unless @database.user_exists?(name)

    redirect '/login' unless @database.get_user_by_name(name).password_matches?(password)

    session[:name] = name
    redirect '/'
  end

  get "/logout" do
    session[:name] = nil
    redirect '/login'
  end

end
