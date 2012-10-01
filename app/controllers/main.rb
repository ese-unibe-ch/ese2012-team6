require 'haml'
require 'models/store/user'
require 'models/store/item'

class Main < Sinatra::Application

  get "/" do
    redirect '/login' unless session[:name]
    user_name = session[:name]
    current_user = App.get_user_by_name(user_name)

    haml :store, :locals => { :users => App.get_users, :current_name => user_name, :current_user => current_user }
  end

  get "/profile/:user_name" do
    redirect '/login' unless session[:name]

    user_name = params[:user_name]
    user = App.get_user_by_name(user_name)

    haml :profile, :locals => { :user => user }
  end

  post "/buy/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = App.get_item_by_id(item_id)

    buyer = App.get_user_by_name(session[:name])
    buyer.buy_item(item)

    redirect back
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