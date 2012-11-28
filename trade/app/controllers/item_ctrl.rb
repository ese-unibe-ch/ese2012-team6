require 'haml'
require 'rdiscount'

require_relative '../models/helpers/storage/picture_uploader'
require_relative '../models/helpers/security/string_checker'
require_relative '../models/store/comment'

# Handles all requests concerning item display, alteration and deletion
class Item < Sinatra::Application
  include Store
  include Storage
  include Security

  before do
    @user = User.by_name(session[:name])
  end

  # shows all Fixed items in the system
  get '/items' do
    redirect '/login' unless @user

    haml :all_items
  end

  # shows all Auction items in the system
  get '/auctions' do
    redirect '/login' unless @user

    haml :auc_items
  end

  # shows item creation form. This must be placed before /item/:item_id handler because the other would intercept
  # this one
  get '/item/new' do
    redirect '/login' unless @user

    haml :new_item
  end

  # shows an item details page
  get '/item/:item_id' do
    redirect '/login' unless @user

    @user.on_behalf_of.acknowledge_item_properties!

    item = Item.by_id(params[:item_id].to_i)

    redirect "/user/#{@user.name}" if item.nil?

    marked_down_description = RDiscount.new(item.description, :smart, :filter_html)

    haml :item_details, :locals => {
        :item => item,
        :marked_down_description => marked_down_description.to_html,
    }
  end

  # shows a page for easy item editing
  get '/item/:item_id/edit' do
    redirect '/login' unless @user

    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)

    redirect "/item/#{item_id}" unless @user.on_behalf_of.can_edit?(item)

    haml :edit_item, :locals => {
        :item => item,
        :show_previous_description => params[:sld] # UG: tell the view whether to display the previous stored description
    }
  end

  #stores a new comment
  post '/item/:item_id/add_comment' do
    redirect '/login' unless session[:name]

    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)
    comment_description = params[:item_comment]

    @user.on_behalf_of.comment(item, comment_description)

    redirect "/item/#{item_id}#comments"
  end

  #deletes a comment
  post '/item/:item_id/delete_comment/:comment_id' do
    redirect '/login' unless session[:name]

    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)
    comment_id = params[:comment_id].to_i
    comment = Comment.by_id(comment_id)
    item.delete_comment(comment)

    redirect "/item/#{item_id}#comments"
  end

  # handles item editing, updates model in database
  post '/item/:item_id/edit' do
    redirect '/login' unless @user

    redirect '/error/invalid_price' unless Store::Item.valid_price?(params[:item_price])
    file = params[:file_upload]
    redirect '/error/wrong_size' if file && file[:tempfile].size > 400*1024

    item_id = params[:item_id].to_i
    item_name = params[:item_name]
    item_price = params[:item_price].to_i
    item_description = params[:item_description]
    item_selling_mode = params[:selling_mode]
    item_increment = params[:item_increment]
    item_end_time = params[:auction_end]

    item = Item.by_id(item_id)

    # UG: necessary because this handler can also be called by scripts
    redirect "/item/#{item_id}" unless @user.on_behalf_of.can_edit?(item)

    if file
      uploader = PictureUploader.with_path(PUBLIC_FOLDER, "/images/items")
      item.image_path = uploader.upload(file, item.id)
    end

    item_to_show_id = item.update(item_name, item_price, item_description, item_selling_mode, item_increment, item_end_time)

    redirect "/item/#{item_to_show_id}"
  end

  #returns the selected image. (Only usable with URL request)
  get '/item/:item_id/images/:image_path' do
    send_file(File.join("public", "images", params[:image_path]))
  end

  # handles item activation/deactivation request
  post '/item/:item_id/update_status' do
    redirect '/login' unless @user

    activate =        (params[:activate] == "true")
    new_end_time  =   (params[:new_end_time])

    item = Item.by_id(Integer(params[:item_id]))

    changed_owner = @user.on_behalf_of.open_item_page_time < item.edit_time && !@user.on_behalf_of.can_activate?(item)

    redirect url('/error/not_owner_of_item') if changed_owner
    redirect "/item/#{params[:item_id]}" unless @user.on_behalf_of.can_activate?(item)

    if item.selling_mode == :fixed and activate
      item.activate_with_end_time(new_end_time)
    else
      item.update_status(activate)
    end

    redirect back
  end

  # handles new item creation, must be PUT request
  put '/item' do
    redirect '/login' unless @user
    redirect back if params[:item_name] == "" or params[:item_price] == "" or params[:item_quantity] == ""

    file = params[:file_upload]
    redirect '/error/wrong_size' if file && file[:tempfile].size > 400*1024

    item_name = StringChecker.destroy_script(params[:item_name])

    redirect '/error/invalid_price' unless Store::Item.valid_price?(params[:item_price])
    fail unless StringChecker.is_numeric?(params[:item_quantity])
    redirect '/error/invalid_quantity' unless Store::Item.valid_price?(params[:item_quantity])

    item_price = params[:item_price].to_i
    item_quantity = params[:item_quantity].to_i
    item_description = params[:item_description] ? params[:item_description] : ""

    item_selling_mode = params[:selling_mode]
    item_increment = params[:item_increment]
    item_end_time = params[:auction_end]

    item_owner = Trader.by_name(params[:owner])
    item = item_owner.propose_item_with_quantity(item_name, item_price, item_quantity, item_selling_mode, item_increment, item_end_time, item_description)

    uploader = PictureUploader.with_path(PUBLIC_FOLDER, "/images/items")
    item.image_path = uploader.upload(file, item.id)

    redirect "/item/#{item.id}" if back == url('/item/new')
    redirect back
  end

  # handles item creation via quick add form
  put '/item/quick_add' do
    redirect '/login' unless @user
    redirect back if params[:item_name] == "" or params[:item_price] == ""

    item_name = StringChecker.destroy_script(params[:item_name])

    redirect '/error/invalid_price' unless Item.valid_price?(params[:item_price])
    item_price = params[:item_price].to_i
    redirect '/error/invalid_quantity' unless Item.valid_price?(params[:item_quantity])
    item_quantity = params[:item_quantity].to_i

    item = @user.on_behalf_of.propose_item_with_quantity(item_name, item_price, item_quantity, :fixed, nil, nil)


    redirect "/item/#{item.id}" if back == url('/item/new')
    redirect back
  end

  # handles item deletion
  delete '/item/:item_id' do
    redirect '/login' unless @user

    item_id = params[:item_id].to_i
    @user.on_behalf_of.delete_item(item_id)

    redirect back
  end

  get '/item/remaining/:item_id' do
    redirect '/login' unless @user

    response.headers['Expires'] = 'Sat, 1 Jan 2005 00:00:00 GMT'
    response.headers['Last-Modified'] = Time.now.strftime("%a, %d %b %Y %H:%M:%S")
    response.headers['Cache-Control'] = 'no-cache, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    item = Item.by_id(Integer(params[:item_id]))
    if item != nil
      Haml::Filters::Plain.render(item.time_delta_string)
    end
  end
end