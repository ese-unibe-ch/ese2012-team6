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

    redirect "/user/#{@user.name}" if item.nil?

    haml :item, :locals => {
      :item => item
    }
  end

  get "/item/:item_id/edit" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)

    haml :edit_item, :locals => {
        :item => item
    }
  end

  post "/item/:item_id/edit" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item_name = params[:item_name]
    item_price = params[:item_price]
    item_description = params[:item_description]
    item = @database.get_item_by_id(item_id)

    item.name = item_name
    item.price = item_price
    item.description = item_description

    redirect "/item/#{item_id}"
  end

  post "/item/:item_id/act_deact/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]
    activate = (activate_str == "true")

    item = @database.get_item_by_id(Integer(params[:item_id]))

    redirect "/item/#{params[:item_id]}" unless @user.can_activate?(item)

    item.active = activate

    redirect back
  end

  put "/item" do
    redirect back if params[:item_name] == "" or params[:item_price] == ""

    item_name = params[:item_name]
    item_price = Integer(params[:item_price])

    item = @user.propose_item(item_name, item_price)
    @database.add_item(item)

    redirect back
  end

  delete "/item/:item_id" do

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    @database.delete_item(item)
    @user.remove_item(item)

    redirect back
  end
end