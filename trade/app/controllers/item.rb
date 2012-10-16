require 'rdiscount'

require_relative '../models/storage/picture_uploader'
require_relative '../models/security/string_manager'
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

    user = @database.get_user_by_name(session[:name])
    user.open_item_page_time = Time.now
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

  #handles undo save description
  post "/item/:item_id/edit/undo_description" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)
    previous_description = Analytics::ActivityLogger.get_previous_description(item)

    item.update(item.name, item.price, previous_description)

    redirect "/item/#{item_id}"
  end

  #handles undo save description
  get "/item/:item_id/edit/description" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)

    haml :edit_description, :locals => { :item => item}
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

    # UG: necessary because this handler can also be called by scripts
    redirect "/item/#{params[:item_id]}" unless @user.can_edit?(item)

    file = params[:file_upload]
    if file
      file_name = Store::Item.id_image_to_filename(item.id, file[:filename])

      uploader = Storage::PictureUploader.with_path("/images/items")
      item.image_path = uploader.upload(file, file_name)
    end

    item.update(item_name, item_price, item_description)

    redirect "/item/#{item_id}"
  end

  #returns the selected image. (Only usable with URL request)
  get "/item/:item_id/images/:image_path" do
    send_file(File.join("public", "images", params[:image_path]))
  end

  # handles item activation/deactivation request
  post "/item/:item_id/act_deact/:activate" do
    redirect '/login' unless session[:name]

    activate_str = params[:activate]
    item = @database.get_item_by_id(Integer(params[:item_id]))
    user = @database.get_user_by_name(session[:name])

    changed_owner = false
    if user.open_item_page_time < item.edit_time && item.owner != user
      changed_owner = true
    end

    if changed_owner
      redirect url("/error/not_owner_of_item")
    end

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

    item = @user.propose_item(item_name, item_price, item_description)

    file = params[:file_upload]
    if file
      file_name = Store::Item.id_image_to_filename(item.id, file[:filename])

      uploader = Storage::PictureUploader.with_path("/images/items")
      item.image_path = uploader.upload(file, file_name)
    end

    redirect "/item/#{item.id}" if back == url("/item/new?")
    redirect back
  end

  # handles item deletion
  delete "/item/:item_id" do

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    @user.delete_item(item)

    redirect back
  end
end