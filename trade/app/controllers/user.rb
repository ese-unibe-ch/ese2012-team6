
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

    haml :profile, :locals => {
        :viewed_user => viewed_user,
        :is_my_profile => is_my_profile
    }
  end

  # Display user profile edit page
  get "/user/:user_name/edit" do
    redirect '/login' unless session[:name]

    haml :edit_profile
  end

  # Handles user profile edit request
  post "/user/:user_name/edit" do

    # TO DO!!!

    redirect "/user/#{@user.name}"
  end

  # Handles user buy request
  post "/user/buy/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = @database.get_item_by_id(item_id)

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
end
