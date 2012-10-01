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

  @@users = []
  @@items = []

  enable :sessions
  set :public_folder, 'app/public'

  def self.add_user(user)
    @@users << user unless @@users.include?(user) or @@users.index{|x| x.id == user.id}
  end

  def self.add_item(item)
    @@items << item unless @@items.include?(item) or @@items.index{|x| x.id == user.id}
  end

  def self.get_users
    return @@users
  end

  def self.get_user_by_name(name)
    return @@users.detect{|user| user.name == name}
  end

  def self.get_item_by_id(id)
    return @@items.detect{|item| item.id == id}
  end

  def self.user_exist?(name)
    return !App.get_user_by_name(name).nil?
  end

  configure :development do
    user_ese = Store::User.named("ese")
    App.add_user(user_ese)
    umbrella_corp = Store::User.named("Umbrella Corp")
    App.add_user(umbrella_corp)
    peter_griffin = Store::User.named("Peter Griffin")
    App.add_user(peter_griffin)

    liver = user_ese.propose_item("Liver", 40).set_active
    heart = user_ese.propose_item("Heart", 80).set_active
    meg = peter_griffin.propose_item("Meg", 2).set_active

    App.add_item(liver)
    App.add_item(heart)
    App.add_item(meg)
  end
end

# Now, run it
App.run!