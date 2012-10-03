require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

class Register < Sinatra::Application

  get "/register" do
    haml :register
  end

  post "/register" do
    user_name = params[:username]
    user_pwd = params[:password]
    user_repeated_pwd = params[:rep_password]

    redirect 'error/user_already_exists' if App.user_exist?(user_name)
    redirect 'error/pwd_rep_no_match' if user_pwd != user_repeated_pwd

    new_user = Store::User.named_with_pwd(user_name, user_pwd)
    App.add_user(new_user)

    redirect '/'
  end
end
