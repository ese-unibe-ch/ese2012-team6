# Handles all requests concerning user display and actions
class User < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  # Handles user display page, shows profile of user
  get "/user/:user_name" do
    redirect '/login' unless session[:name]

    viewed_user = @database.get_user_by_name(params[:user_name])
    is_my_profile = @user == viewed_user
    marked_down_description = RDiscount.new(viewed_user.description, :smart, :filter_html)

    haml :profile, :locals => {
        :viewed_user => viewed_user,
        :is_my_profile => is_my_profile,
        :marked_down_description => marked_down_description.to_html
    }
  end

  # Display user profile edit page
  get "/user/:user_name/edit" do
    redirect '/login' unless session[:name]

    haml :edit_profile
  end

  # Handles user profile edit request
  post "/user/:user_name/edit" do

    old_pwd = params[:password_old]
    new_pwd = params[:password_new]
    new_pwd_rep = params[:rep_password]
    new_desc = params[:description]

    redirect "/error/wrong_password" unless @user.password_matches?(old_pwd)
    @user.description = new_desc

    if new_pwd != ""

      redirect "/error/pwd_unsafe" unless String_Manager::is_safe_pw?(new_pwd)

      @user.change_password(new_pwd)
    end

    redirect "/user/#{@user.name}"
  end

  # Handles user buy request
  post "/user/buy/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)
    user = @database.get_user_by_name(session[:name])

    changed_item_details = true
    if user.open_item_page_time >= item.edit_time
      changed_item_details = false
    end

    if changed_item_details
      redirect url("/error/item_changed_details")
    end

    buy_success, buy_message = @user.buy_item(item)

    if buy_success
      redirect back
    else
      redirect url("/error/#{buy_message}")
    end
  end

  # Shows a list of all users
  get "/users" do
    redirect '/login' unless session[:name]

    haml :all_users
  end

  # Handles user's picture upload
  post "/user/:name/images" do
    return 404 unless @user.name

    file = params[:file_upload]
    redirect to("/user/#{params[:name]}") unless file

    return 413 if file[:tempfile].size > 400*1024

    filename = Store::User.id_image_to_filename(@user.name, file[:filename])

    uploader = Storage::PictureUploader.with_path("/images/users")
    @user.image_path = uploader.upload(file, filename)

    redirect to("/user/#{params[:name]}")
  end
end
