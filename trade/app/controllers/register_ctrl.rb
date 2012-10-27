require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')

# Handles all requests concerning user registration
class Register < Sinatra::Application
  include Security
  include Store

  # Shows registration form
  get "/register" do
    haml :register
  end

  # Handles registration inputs and creates new user in database
  post "/register" do
    user_name = StringChecker.destroy_script(params[:username]) #remove all whitespaces and special characters
    user_pwd = params[:password].gsub(/\s+/, "")
    user_repeated_pwd = params[:rep_password].gsub(/\s+/, "")
    user_description = params[:description].strip #remove leading and trailing whitespaces

    redirect 'error/no_user_name' if user_name == ""
    redirect 'error/user_already_exists' if User.exists?(:name => user_name)
    redirect 'error/pwd_unsafe' unless StringChecker.is_safe_pw?(user_pwd)
    redirect 'error/pwd_rep_no_match' if user_pwd != user_repeated_pwd

    new_user = Store::User.named(user_name, :password => user_pwd, :description => user_description)
    new_user.save

    redirect '/'
  end
end
