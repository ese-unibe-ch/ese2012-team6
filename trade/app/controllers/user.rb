class User < Sinatra::Application

  before do
    @user = App.get_user_by_name(session[:name])
  end

  get "/profile/:user_name" do
    redirect '/login' unless session[:name]

    haml :profile, :locals => { :user => App.get_user_by_name(params[:user_name])}
  end

  post "/buy/:item_id" do
    redirect '/login' unless session[:name]

    item_id = Integer(params[:item_id])
    item = App.get_item_by_id(item_id)

    buy_success, buy_message = @user.buy_item(item)

    if buy_success
      redirect back
    else
      redirect url("/error/#{buy_message}")
    end
  end

  get "/users" do
    redirect '/login' unless session[:name]

    haml :users
  end
end
