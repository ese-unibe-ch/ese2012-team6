class Item < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  get "/items" do
    redirect '/login' unless session[:name]

    haml :all_items
  end

  get "/item/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    haml :item, :locals => {
      :item => item
    }
  end

  post "/act_deact/:item_id/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]
    activate = (activate_str == "true")

    item = @database.get_item_by_id(Integer(params[:item_id]))
    item.active = activate

    redirect back
  end

  post "/delete_item/:item_id" do
    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    @database.delete_item(item)
    @user.remove_item(item)

    redirect back
  end

  post "/create_item" do
    redirect back if params[:item_name] == "" or params[:item_price] == ""

    item_name = params[:item_name]
    item_price = Integer(params[:item_price])

    item = @user.propose_item(item_name, item_price)
    @database.add_item(item)

    redirect back
  end
end