require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

# Handles all requests concerning user registration
class Register < Sinatra::Application

  before do
    @database = Storage::Database.instance
  end

  # Shows registration form
  get "/register" do
    haml :register
  end

  # Handles registration inputs and creates new user in database
  post "/register" do
    user_name = params[:username]
    user_pwd = params[:password]
    user_repeated_pwd = params[:rep_password]
    user_description = params[:description]

    redirect 'error/user_already_exists' if @database.user_exists?(user_name)
    redirect 'error/pwd_rep_no_match' if user_pwd != user_repeated_pwd

    new_user = Store::User.named_pwd_description(user_name, user_pwd, user_description)
    @database.add_user(new_user)

    redirect '/'
  end
end
