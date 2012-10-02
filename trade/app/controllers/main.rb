require 'haml'
require './models/store/user'
require './models/store/item'

class Main < Sinatra::Application

  before do
    @user = App.get_user_by_name(session[:name])
  end

  get "/" do
    redirect '/login' unless session[:name]

    haml :store, :locals => { :users => App.get_users, :current_name => @user.name, :current_user => @user }
  end

  get "/profile/:user_name" do
    redirect '/login' unless session[:name]

    haml :profile, :locals => { :user => @user }
  end

  post "/buy/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = App.get_item_by_id(item_id)

    buy_success, buy_message = @user.buy_item(item)

    if buy_success
      redirect back
    else
      redirect url("/error/#{buy_message}")
    end
  end

  get "/error/:error_msg" do
    haml :error, :locals => { :error_message => params[:error_msg]}
  end

  get "/users" do
    redirect '/login' unless session[:name]

    haml :users
  end

  get "/items" do
    redirect '/login' unless session[:name]

    haml :items
  end

  post "/act_deact/:item_id/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]
    activate = (activate_str == "true")

    item = App.get_item_by_id(Integer(params[:item_id]))
    item.active = activate

    redirect back
  end
end