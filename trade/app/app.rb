require 'rubygems'
require 'sinatra'
require 'haml'
require 'require_relative'
require 'rack-flash'

require_relative('models/store/item')
require_relative('models/store/user')
require_relative('models/store/organization')
require_relative('models/store/trading_authority')

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

  include Store
  enable :sessions
  set :public_folder, 'app/public'

  configure :development do
    #add default users
    (user_admin = User.named("admin")).save
    (user_ese = User.named("ese")).save
    (user_ese2 = User.named("ese2")).save
    (umbrella_corp = User.named("umbrellacorp")).save
    (peter_griffin = User.named("petergriffin")).save

    #add default items
    (liver = user_ese.propose_item("Liver", 40)).activate
    (heart = umbrella_corp.propose_item("Heart", 80)).activate
    (meg = peter_griffin.propose_item("Meg", 2)).activate
    random = umbrella_corp.propose_item("Random", 50)
    (bender = umbrella_corp.propose_item("Bender", 110)).activate

    #add default organization
   (organization_mordor_inc = Organization.named("MordorInc", :credits => 200, :admin => user_ese)).save
    organization_mordor_inc.add_member(peter_griffin)

    @last_refresh = Time.now
  end

  def self.run!(options={})
    TradingAuthority.timed(10).start
    super
  end
end

# Now, run it
App.run!

