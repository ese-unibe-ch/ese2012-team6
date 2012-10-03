require 'require_relative'
require 'tilt/haml'
require_relative '../models/trade/user'
require_relative '../models/trade/item'

class Main < Sinatra::Application

  get "/" do
    redirect '/login' unless session[:name]

    haml :list_active_items, :locals => { :time => Time.now,
                                          :active_items => Trade::Item.all_active,
                                          :money => Trade::User.by_name(session[:name]).credits,
                                          :user_name => session[:name]}

  end

  get "/show_my_items" do
    user = Trade::User.by_name(session[:name])
    items = user.items
    haml :list_my_items, :locals => { :time => Time.now,
                                     :user_name => session[:name],
                                     :money =>Trade::User.by_name(session[:name]).credits,
                                     :items_of_user => items}
  end

  get "/create_item_site" do
    haml :create_item, :locals => { :time => Time.now,
                                    :money =>Trade::User.by_name(session[:name]).credits,
                                    :user_name => session[:name]}
  end

  post "/create_item" do
    item_name = params[:item_name]
    price = params[:price].to_i
    user = Trade::User.by_name(session[:name])
    user.create_item(item_name, price)
    redirect "/show_my_items"
  end

  post "/delete_item/:item_id" do
    item_id_string = params[:item_id]
    user = Trade::User.by_name(session[:name])
    items = user.items
    items.delete_if{|item| item.id.to_s == item_id_string}
    Trade::Item.all.delete_if{|item| item.id.to_s == item_id_string}
    redirect"/show_my_items"
  end


  post "/activate/:item_id" do
    item_id_string = params[:item_id]
    user = Trade::User.by_name(session[:name])
    items = user.items
    item = items.detect {|item| item.id.to_s == item_id_string}
    user.activate(item)
    redirect "/show_my_items"
  end


  post "/deactivate/:item_id" do
    item_id_string = params[:item_id]
    user = Trade::User.by_name(session[:name])
    items = user.items
    item = items.detect {|item| item.id.to_s == item_id_string}
    user.deactivate(item)
    redirect "/show_my_items"
  end


  get "/checkout_user/:user_name" do
    user_name = params[:user_name]
    user = Trade::User.by_name(user_name)
    items = user.items
    haml :list_users, :locals => { :time  => Time.now ,
                                  :user => user,
                                  :items_of_user => items,
                                  :money =>Trade::User.by_name(session[:name]).credits,
                                  :user_name => session[:name]}
  end


  post "/buy/:item_id" do
    item_id_string = params[:item_id]
    items = Trade::Item.all
    item = items.detect {|item| item.id.to_s == item_id_string}
    user = Trade::User.by_name(session[:name])
    if user.credits < item.price
      redirect "/not_enough_money/#{item.price}"
    else
      user.buy(item)
      redirect "/"
    end
  end


  get "/not_enough_money/:price" do
    price = params[:price].to_i
    money = Trade::User.by_name(session[:name]).credits
    difference = price - money
    haml :not_enough_money, :locals =>  {:time  => Time.now ,
                                         :difference => difference,
                                         :money => money,
                                         :user_name => session[:name]}
  end


end