require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')
require_relative('../models/helpers/storage/picture_uploader')
require_relative('../models/store/trader')
require_relative('../models/store/purchase')
require_relative('../models/helpers/exceptions/purchase_error')

# Handles all requests concerning user display and actions
class User < Sinatra::Application
  include Store
  include Security
  include Storage

  before do
    @user = User.by_name(session[:name])
  end

  # handle on behalf of selector change
  post '/user/work_on_behalf_of/' do
    org_name = params[:on_behalf_of]
    org = Trader.by_name(org_name)
    @user.work_on_behalf_of(org)
    redirect back
  end

  # Handles user display page, shows profile of user
  get '/user/:user_name' do
    redirect '/login' unless @user

    viewed_user = User.by_name(params[:user_name])
    is_my_profile = (@user == viewed_user)
    marked_down_description = RDiscount.new(viewed_user.description, :smart, :filter_html)

    haml :user_profile, :locals => {
        :viewed_user => viewed_user,
        :is_my_profile => is_my_profile,
        :marked_down_description => marked_down_description.to_html
    }
  end

  # Display user profile edit page
  get '/user/:user_name/edit' do
    redirect '/login' unless @user

    haml :edit_profile
  end

  # Handles user profile edit request
  post '/user/:user_name/edit' do
    redirect '/login' unless @user

    old_pwd = params[:password_old]
    new_pwd = params[:password_new]
    new_pwd_rep = params[:rep_password]
    new_desc = params[:description]

    redirect '/error/wrong_password' unless @user.password_matches?(old_pwd)
    @user.description = new_desc
    redirect "/user/#{@user.name}" if new_pwd == ""

    redirect 'error/pwd_rep_no_match' if new_pwd != new_pwd_rep
    redirect '/error/pwd_unsafe' unless StringChecker.is_safe_pw?(new_pwd)

    @user.change_password(new_pwd)

    redirect "/user/#{@user.name}"
  end

  post '/user/buy/:item_id' do
    redirect '/login' unless @user

    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)

    if item.isAuction?
      redirect "user/bid/#{item_id}"
    end

    redirect '/error/invalid_quantity' unless StringChecker.is_numeric?(params[:buy_amount])
    redirect url('/error/item_changed_details') unless @user.on_behalf_of.knows_item_properties?(item)

    quantity = params[:buy_amount].to_i

    begin
      @user.on_behalf_of.purchase(item, quantity)
    rescue Exceptions::PurchaseError => error
      redirect "/error/#{error.message}"
    end

    redirect "/user/#{@user.name}" if @user.working_as_self?
    redirect "/organization/#{@user.on_behalf_of.name}"
  end

  # Handles user buy request
  post '/user/confirm/:purchase_id' do
    redirect '/login' unless @user
    purchase_id = params[:purchase_id].to_i

    purchase = @user.on_behalf_of.pending_purchases.detect{|purchase| purchase.id == purchase_id}
    @user.on_behalf_of.confirm_purchase(purchase)

    redirect "/user/#{@user.name}" if @user.working_as_self?
    redirect "/organization/#{@user.on_behalf_of.name}"
  end

  get '/user/bid/:item_id' do
    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)
    haml :bid, :locals => {:action_url => "/user/bid/#{params[:item_id]}", :item => item}
  end

  post '/user/bid/:item_id' do
    redirect '/login' unless @user

    amount = params[:amount].to_i

    item_id = params[:item_id].to_i
    item = Item.by_id(item_id)

    redirect url('/error/item_changed_details') unless @user.on_behalf_of.knows_item_properties?(item)

    @user.on_behalf_of.bid(item, amount)

    # redirect url("/error/#{buy_message}") unless buy_success
    redirect back
  end

  # Shows a list of all users
  get '/users' do
    redirect '/login' unless @user

    haml :all_users
  end

  # Handles user's picture upload
  post '/user/:name/images' do
    redirect '/login' unless @user

    file = params[:file_upload]

    redirect to("/user/#{params[:name]}") unless file
    redirect '/error/wrong_size' if file[:tempfile].size > 400*1024

    uploader = PictureUploader.with_path(PUBLIC_FOLDER, "/images/users")
    @user.image_path = uploader.upload(file, @user.id)

    redirect to("/user/#{params[:name]}")
  end

  # handles credit transfer request from user to organization
  post '/user/send_money/:org_name' do
    redirect '/login' unless @user

    org_name = params[:org_name]
    org = Organization.by_name(org_name)

    fail unless org.has_member?(@user)
    redirect '/error/wrong_transfer_amount' unless (StringChecker.is_numeric?(params[:gift_amount]) && Integer(params[:gift_amount]) >= 0)

    amount = params[:gift_amount].to_i

    success = @user.send_money_to(org, amount)

    redirect '/error/user_credit_transfer_failed' unless success

    redirect back
  end

  # Displays the 'suspend_prov' page
  get '/suspend_prov' do
    redirect '/login' unless @user

    @user.items.each do |item|
      redirect '/error/delete_failed' if item.isAuction? && item.active?
    end

    haml :suspend_prov
  end

  # Displays the 'suspend' page
  get '/suspend' do
    redirect '/login' unless @user
    @user.suspend
    @user.logout
    @user = nil
    session[:name] = nil

    haml :suspend
  end
end
