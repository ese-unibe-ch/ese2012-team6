require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/security/password_handler')

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
    user_name = params[:username].gsub(/\s+/, "") #remove all whitespaces
    user_pwd = params[:password].gsub(/\s+/, "")
    user_repeated_pwd = params[:rep_password].gsub(/\s+/, "")
    user_description = params[:description].strip #remove leading and trailing whitespaces

    password_checker = Security::PasswordHandler.new

    redirect 'error/user_already_exists' if @database.user_exists?(user_name)
    redirect 'error/pwd_unsafe' unless password_checker.is_safe_pw?(user_pwd)
    redirect 'error/pwd_rep_no_match' if user_pwd != user_repeated_pwd
    redirect 'error/no_user_name' if user_name == ""

    new_user = Store::User.named_pwd_description(user_name, user_pwd, user_description)
    @database.add_user(new_user)

    redirect '/'
  end
end
