require 'rubygems'
require 'bundler/setup'
require 'require_relative'

require 'sinatra'
require 'tilt/haml'
require_relative 'models/trade/user'
require_relative 'controllers/main'
require_relative 'controllers/authentication'

class App < Sinatra::Base

  use Authentication
  use Main

  enable :sessions
  set :public_folder, 'app/public'

  configure :development do
    jack = Trade::User.named( 'Jack' )
    jack.save
    jack.create_item('Computer', 1000).activate
    john = Trade::User.named( 'John' )
    john.save
    john.create_item('Nintendo', 200).activate
    ese = Trade::User.named( 'ese')
    ese.save
    ese.create_item('XBOX', 250).activate
  end

end

# Now, run it
App.run!