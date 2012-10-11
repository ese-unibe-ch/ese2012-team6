require 'rdiscount'

# Handles all requests concerning item display, alteration and deletion
class Item < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  # shows all items in the system
  get "/items" do
    redirect '/login' unless session[:name]

    haml :all_items
  end

  # shows item creation form. This must be placed before /item/:item_id handler because the other would intercept
  # this one
  get "/item/new" do
    haml :new_item
  end

  # shows an item details page
  get "/item/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    redirect "/user/#{@user.name}" if item.nil?

    marked_down_description = RDiscount.new(item.description, :smart, :filter_html)

    haml :item, :locals => {
      :item => item,
      :marked_down_description => marked_down_description.to_html
    }

  end

  # shows a page for easy item editing
  get "/item/:item_id/edit" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)

    haml :edit_item, :locals => {
        :item => item
    }
  end

  # handles item editing, updates model in database
  post "/item/:item_id/edit" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item_name = params[:item_name]

    redirect "/error/invalid_price" unless Store::Item.valid_price?(params[:item_price])

    item_price = Integer(params[:item_price])
    item_description = params[:item_description]
    item = @database.get_item_by_id(item_id)

    # UG: necessary because item.update fails if item owner can not edit item, e.g if the item is active
    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)

    item.update(item_name, item_price, item_description)

    redirect "/item/#{item_id}"
  end

  # handles item activation/deactivation request
  post "/item/:item_id/act_deact/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]

    item = @database.get_item_by_id(Integer(params[:item_id]))

    redirect "/item/#{params[:item_id]}" unless @user.can_activate?(item)

    item.update_status(activate_str)

    redirect back
  end

  # handles new item creation, must be PUT request
  put "/item" do
    redirect back if params[:item_name] == "" or params[:item_price] == ""

    item_name = params[:item_name]

    redirect "/error/invalid_price" unless Store::Item.valid_price?(params[:item_price])

    item_price = Integer(params[:item_price])
    item_description = params[:item_description]

    item = @user.propose_item(item_name, item_price)
    item.description = item_description unless item_description.nil? or item_description == ""

    if back == url("/item/new?")
      redirect "/item/#{item.id}"
    else
      redirect back
    end
end

  # handles item deletion
  delete "/item/:item_id" do

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    @user.delete_item(item)

    redirect back
  end
end