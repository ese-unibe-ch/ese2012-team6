
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

    haml :item, :locals => {
      :item => item
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

    #fail "Not a valid number" unless Store::Item.valid_price?(params[:item_price])
    redirect "/error/invalid_price" unless Store::Item.valid_price?(params[:item_price])

    item_price = Integer(params[:item_price])
    item_description = params[:item_description]
    item = @database.get_item_by_id(item_id)

    file = params[:file_upload]
    filename = item.id_image_to_filename(item_id, file[:filename])
    FileUtils::cp(file[:tempfile].path, File.join("public", "images", filename))

    item.name = item_name
    item.price = item_price
    item.description = item_description
    item.image_path = filename

    redirect "/item/#{item_id}"
  end

  #returns the selected image. (Only usable with URL request)
  get "/item/:item_id/images/:image_path" do
    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    send_file(File.join("public","images", params[:image_path]))
  end

  # handles item activation/deactivation request
  post "/item/:item_id/act_deact/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]
    activate = (activate_str == "true")

    item = @database.get_item_by_id(Integer(params[:item_id]))

    redirect "/item/#{params[:item_id]}" unless @user.can_activate?(item)

    item.active = activate

    redirect back
  end

  # handles new item creation, must be PUT request
  put "/item" do
    redirect back if params[:item_name] == "" or params[:item_price] == ""

    item_name = params[:item_name]

    #fail "Not a valid number" unless Store::Item.valid_price?(params[:item_price])
    redirect "/error/invalid_price" unless Store::Item.valid_price?(params[:item_price])

    item_price = Integer(params[:item_price])
    item_description = params[:item_description]

    item = @user.propose_item(item_name, item_price)
    item.description = item_description unless item_description.nil? or item_description == ""

    @database.add_item(item)

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
    @database.delete_item(item)
    @user.remove_item(item)

    redirect back
  end
end