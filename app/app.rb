require 'rubygems'
require 'sinatra'
require 'haml'

require 'models/store/item'
require 'models/store/user'

require 'controllers/authentication'
require 'controllers/main'

class App < Sinatra::Base

  use Authentication
  use Main

  enable :sessions
  set :public_folder, 'app/public'

  configure :development do

  end

end

# Now, run it
App.run!