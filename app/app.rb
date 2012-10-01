require 'rubygems'
require 'sinatra'
require 'haml'

require '../app/models/store/item'
require '../app/models/store/user'

require 'app/controllers/main'
require 'app/controllers/authentication'

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