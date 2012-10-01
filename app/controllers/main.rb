require 'haml'
require 'models/store/user'
require 'models/store/item'

class Main < Sinatra::Application

  get "/" do
    redirect '/login' unless session[:name]

    haml :store, :locals => { :users => App.get_users, :current_name => session[:name] }

  end

  get "/profile/:user_id" do
    user_id = Integer(params[:user_id])
    user = App.get_user_by_id(user_id)

    haml :profile, :locals => { :user => user }
  end

  post "/buy/:item_id" do
    item_id = Integer(params[:item_id])
    item = App.get_item_by_id(item_id)

    buyer = App.get_item_by_id
  end

end