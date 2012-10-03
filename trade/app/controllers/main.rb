require 'haml'
require_relative('../models/store/user')
require_relative('../models/store/item')

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

    haml :profile, :locals => { :user => App.get_user_by_name(params[:user_name])}
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

    case params[:error_msg]
      when "item_no_owner"
        error_message = "Item does not belong to anybody"
      when "not_enough_credits"
        error_message = "Buyer does not have enough credits"
      when "buy_inactive_item"
        error_message = "Trying to buy inactive item"
      when "seller_not_own_item"
        error_message = "Seller does not own item to buy"
      when "user_no_exists"
        error_message = "User is not registered in the system"
      when "login_no_pwd_user"
        error_message = "Empty username or password"
    end

    haml :error, :locals => { :error_message => error_message}
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