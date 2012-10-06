class User < Sinatra::Application

  before do
    @database = Storage::Database.instance
    @user = @database.get_user_by_name(session[:name])
  end

  get "/user/:user_name" do
    redirect '/login' unless session[:name]

    viewed_user = @database.get_user_by_name(params[:user_name])
    is_my_profile = @user == viewed_user

    haml :profile, :locals => {
        :viewed_user => viewed_user,
        :is_my_profile => is_my_profile
    }
  end

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

  get "/users" do
    redirect '/login' unless session[:name]

    haml :all_users
  end
end
