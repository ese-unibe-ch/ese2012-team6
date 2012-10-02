require 'rubygems'
require 'sinatra'
require 'haml'

require 'models/store/item.rb'
require 'models/store/user.rb'

require 'controllers/authentication.rb'
require 'controllers/main.rb'

class App < Sinatra::Base

  use Authentication
  use Main

  @@users = []
  @@items = []

  enable :sessions
  set :public_folder, 'app/public'

  def self.add_user(user)
    @@users << user unless (@@users.include?(user) or @@users.index{|x| x.name == user.name} != nil)
  end

  def self.add_item(item)
    @@items << item unless (@@items.include?(item) or @@items.index{|x| x.id == item.id} != nil)
  end

  def self.get_users
    return @@users
  end

  def self.get_items
    return @@items
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
    user_admin = Store::User.named("admin")
    App.add_user(user_admin)
    user_ese = Store::User.named("ese")
    App.add_user(user_ese)
    umbrella_corp = Store::User.named("umbrellacorp")
    App.add_user(umbrella_corp)
    peter_griffin = Store::User.named("petergriffin")
    App.add_user(peter_griffin)

    liver = user_ese.propose_item("Liver", 40)
    heart = umbrella_corp.propose_item("Heart", 80)
    meg = peter_griffin.propose_item("Meg", 2)
    random = umbrella_corp.propose_item("Random", 50)

    liver.set_active
    heart.set_active
    meg.set_active

    App.add_item(liver)
    App.add_item(heart)
    App.add_item(meg)
    App.add_item(random)
  end
end

# Now, run it
App.run!