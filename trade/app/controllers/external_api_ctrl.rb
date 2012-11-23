require 'json'
require 'rdiscount'
require_relative '../models/store/item'
require_relative '../models/store/trader'
require_relative '../models/store/user'

class ExternalApi < Sinatra::Application
  include Store

  get '/api/items' do
    content_type :json

    filter = params[:filter]

    case filter
      when "none"
        items = Item.allFixed
      when "active"
        items = Item.allFixed.select {|item| item.state == :active}
      when "inactive"
        items = Item.allFixed.select {|item| item.state == :inactive}
    end

    items.to_json
  end

  get '/api/items/description' do
    content_type :json

    format = params[:format]
    item = Item.by_id(params[:id].to_i)

    if item.nil?
      "no_such_item"
    else
      case format
        when "text"
          item.description
        when "html"
          RDiscount.new(item.description, :smart, :filter_html).to_html
        else
          item.description
      end
    end
  end

  get '/api/items/comments' do
    content_type :json

    item = Item.by_id(params[:id].to_i)

    item.nil? ? "no_such_item" : item.comments.to_json
  end

  post '/api/items/buy' do
    content_type :json

    item = Item.by_id(params[:item_id].to_i)
    "no_such_item" if item.nil?

    auth_token = params[:auth_token].split(",")

    username = auth_token[0].strip
    password = auth_token[1].strip

    user = User.by_name(username)
    "no_such_user" if user.nil?
    "authentication_failed" unless user.password_matches?(password)

    success, message = user.purchase(item, params[:quantity].to_i)

    success ? "success" : message
  end
end