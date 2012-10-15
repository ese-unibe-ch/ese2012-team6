require 'rubygems'
require 'sinatra'
require 'haml'
require 'require_relative'

require_relative('models/store/item')
require_relative('models/store/user')
require_relative('models/storage/database')

require_relative('controllers/authentication')
require_relative('controllers/main')
require_relative('controllers/register')
require_relative('controllers/item')
require_relative('controllers/user')
require_relative('controllers/activity_logger')

class App < Sinatra::Base

  use Authentication
  use Main
  use Register
  use Item
  use User
  use ActivityLogger

  enable :sessions
  set :public_folder, 'app/public'

  configure :development do
    @database = Storage::Database.instance

    user_admin = Store::User.named("admin")
    @database.add_user(user_admin)
    user_ese = Store::User.named("ese")
    @database.add_user(user_ese)
    umbrella_corp = Store::User.named("umbrellacorp")
    @database.add_user(umbrella_corp)
    peter_griffin = Store::User.named("petergriffin")
    @database.add_user(peter_griffin)

    liver = user_ese.propose_item("Liver", 40)
    heart = umbrella_corp.propose_item("Heart", 80)
    meg = peter_griffin.propose_item("Meg", 2)
    random = umbrella_corp.propose_item("Random", 50)
    bender = umbrella_corp.propose_item("Bender", 110)

    liver.set_active
    heart.set_active
    meg.set_active
    bender.set_active
  end
end

# Now, run it
App.run!