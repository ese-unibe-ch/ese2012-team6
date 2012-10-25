require 'rubygems'
require 'sinatra'
require 'haml'
require 'require_relative'
require 'rack-flash'

require_relative('models/store/item')
require_relative('models/store/user')
require_relative('models/store/organization')

require_relative('controllers/authentication_ctrl')
require_relative('controllers/main_ctrl')
require_relative('controllers/register_ctrl')
require_relative('controllers/item_ctrl')
require_relative('controllers/user_ctrl')
require_relative('controllers/activity_logger_ctrl')
require_relative('controllers/organization_ctrl')

class App < Sinatra::Base

  use Rack::Flash

  # Controllers
  use Authentication
  use Main
  use Register
  use Item
  use User
  use ActivityLogger
  use Organization

  enable :sessions
  set :public_folder, 'app/public'

  configure :development do
    #add default users
    (user_admin = Store::User.named("admin")).save
    (user_ese = Store::User.named("ese")).save
    (user_ese2 = Store::User.named("ese2")).save
    (umbrella_corp = Store::User.named("umbrellacorp")).save
    (peter_griffin = Store::User.named("petergriffin")).save

    #add default items
    (liver = user_ese.propose_item("Liver", 40)).activate
    (heart = umbrella_corp.propose_item("Heart", 80)).activate
    (meg = peter_griffin.propose_item("Meg", 2)).activate
    random = umbrella_corp.propose_item("Random", 50)
    (bender = umbrella_corp.propose_item("Bender", 110)).activate


    #add default organization
   (organization_Mordor_inc = Store::Organization.named("Mordor Inc.")).save
    organization_Mordor_inc.add_member(user_ese)
    organization_Mordor_inc.add_member(peter_griffin)
    organization_Mordor_inc.add_admin(user_ese)
    organization_Mordor_inc.send_money(200)
  end
end

# Now, run it
App.run!

