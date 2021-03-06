require 'rubygems'
require 'sinatra'
require 'haml'
require 'require_relative'
require 'rack-flash'

require_relative('models/store/item')
require_relative('models/store/user')
require_relative('models/store/organization')
require_relative('models/store/trading_authority')
require_relative('models/store/auction_timer')
require_relative('models/store/suspender')
require_relative('models/store/offer')

require_relative('controllers/authentication_ctrl')
require_relative('controllers/main_ctrl')
require_relative('controllers/register_ctrl')
require_relative('controllers/item_ctrl')
require_relative('controllers/user_ctrl')
require_relative('controllers/activity_logger_ctrl')
require_relative('controllers/organization_ctrl')
require_relative('controllers/external_api_ctrl')

APP_STARTUP_PATH = File.dirname(__FILE__)
PUBLIC_FOLDER = File.join(APP_STARTUP_PATH, "public")

class App < Sinatra::Base

  # Controllers
  use Rack::Flash
  use Authentication
  use Main
  use Register
  use Item
  use User
  use ActivityLogger
  use Organization
  use ExternalApi

  include Store

  enable :sessions
  set :root, APP_STARTUP_PATH
  set :public_folder, PUBLIC_FOLDER

  configure :development do
    #add default users
    (user_admin = User.named("admin")).save
    (user_ese = User.named("ese", :email => 'awesome.trading.app@gmail.com')).save
    (user_ese2 = User.named("ese2", :email => 'awesome.trading.app@gmail.com')).save
    (user_ese3 = User.named("ese3", :email => 'awesome.trading.app@gmail.com')).save
    (user_ese4 = User.named("ese4")).save
    (user_ese5 = User.named("ese5")).save
    (user_ese6 = User.named("ese6")).save
    (user_ese7 = User.named("ese7")).save
    (user_ese8 = User.named("ese8")).save
    (user_ese9 = User.named("ese9")).save
    (user_ese10 = User.named("ese10")).save
    (umbrella_corp = User.named("umbrellacorp")).save
    (peter_griffin = User.named("petergriffin")).save

    #add default items
    (liver = user_ese.propose_item("Liver", 40, :auction, 5, "2013-11-11 20:00:00")).activate
    (heart = umbrella_corp.propose_item("Heart", 80, :fixed, nil, nil)).activate
    (meg = user_ese2.propose_item_with_quantity("Meg", 2, 4, :fixed, nil, nil, "This is a description")).activate
    random = umbrella_corp.propose_item("Random", 50, :fixed, nil, nil)
    (bender = umbrella_corp.propose_item("Bender", 110, :fixed, nil, nil)).activate

    fresh_air = Store::Offer.create("fresh air", 7, 3, user_ese)

    user_ese.comment(meg, "This is a comment by ese")
    user_ese2.comment(meg, "This is another comment by ese2")

    #add default organization
   (organization_mordor_inc = Organization.named("MordorInc", :credits => 200, :admin => user_ese)).save
    organization_mordor_inc.add_member(peter_griffin)
  end

  def self.run!(options={})
    TradingAuthority.timed(1000)
    TradingAuthority.start
    AuctionTimer.check_auctions
    AuctionTimer.timed(10).start
    Suspender.timed('1s')
    super
  end
end

# Now, run it
App.run!


