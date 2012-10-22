# Handles all requests concerning user display and actions
class User < Sinatra::Application

  before do
    @user = Store::User.by_name(session[:name])
  end

  # handle on behalf of selector change
  post "/user/work_on_behalf_of/" do
    org_id = params[:on_behalf_of]
    org = Store::Organization.by_name(org_id)
    if org == nil
      org=@user
    end

   @user.work_on_behalf_of(org)


   redirect back
  end

  # Handles user display page, shows profile of user
  get "/user/:user_name" do
    redirect '/login' unless @user

    viewed_user = Store::User.by_name(params[:user_name])
    is_my_profile = (@user == viewed_user)
    marked_down_description = RDiscount.new(viewed_user.description, :smart, :filter_html)

    haml :profile, :locals => {
        :viewed_user => viewed_user,
        :is_my_profile => is_my_profile,
        :marked_down_description => marked_down_description.to_html
    }
  end

  # Display user profile edit page
  get "/user/:user_name/edit" do
    redirect '/login' unless @user

    haml :edit_profile
  end

  # Handles user profile edit request
  post "/user/:user_name/edit" do

    old_pwd = params[:password_old]
    new_pwd = params[:password_new]
    new_pwd_rep = params[:rep_password]
    new_desc = params[:description]

    redirect 'error/pwd_rep_no_match' if new_pwd != new_pwd_rep
    redirect "/error/wrong_password" unless @user.password_matches?(old_pwd)

    @user.description = new_desc

    if new_pwd != ""
      redirect "/error/pwd_unsafe" unless Security::StringChecker.is_safe_pw?(new_pwd)

      @user.change_password(new_pwd)
    end

    redirect "/user/#{@user.name}"
  end

  # Handles user buy request
  post "/user/buy/:item_id" do
    redirect '/login' unless @user

    item_id = Integer(params[:item_id])
    item = Store::Item.by_id(item_id)

    changed_item_details =  @user.open_item_page_time < item.edit_time
    redirect url("/error/item_changed_details") if changed_item_details

    buy_success, buy_message = @user.on_behalf_of.buy_item(item)

    if buy_success
      redirect back
    else
      redirect url("/error/#{buy_message}")
    end
  end

  # Shows a list of all users
  get "/users" do
    redirect '/login' unless @user

    haml :all_users
  end

  # Handles user's picture upload
  post "/user/:name/images" do
    redirect '/login' unless @user

    file = params[:file_upload]
    redirect to("/user/#{params[:name]}") unless file

    redirect "/error/wrong_size" if file[:tempfile].size > 400*1024

    filename = Store::User.id_image_to_filename(@user.name, file[:filename])

    uploader = Storage::PictureUploader.with_path("/images/users")
    @user.image_path = uploader.upload(file, filename)

    redirect to("/user/#{params[:name]}")
  end

  post '/user/send_money/:org_name' do
    redirect '/login' unless @user

    org_name = params[:org_name]
    org = Store::Organization.by_name(org_name)

    fail unless org.has_member?(@user)
    redirect "/error/wrong_transfer_amount" unless (!!(params[:gift_amount] =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(params[:gift_amount]) >= 0)

    amount = Integer(params[:gift_amount])

    success = @user.send_money_to(org, amount)

    redirect "/error/credit_transfer_failed" unless success

    redirect back
  end
end
