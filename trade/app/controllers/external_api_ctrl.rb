require 'json'
require_relative '../models/store/item'
require_relative '../models/store/trader'

class ExternalApi < Sinatra::Application
  include Store

  get '/api/items' do
    content_type :json

    filter = params[:filter]

    case filter
      when "none"
        items = Item.all
      when "active"
        items = Item.all.select {|item| item.state = :active}
      when "inactive"
        items = Item.all.select {|item| item.state = :inactive}
    end

    items.to_json
  end

  get '/api/items/description' do
    content_type :json

    item = Item.by_id(params[:id])

    "no_such_item" if item.nil?

    item.description
  end

  get '/api/items/comments' do
    content_type :json

    item = Item.by_id(params[:id])

    "no_such_item" if item.nil?

    item.comments.to_json
  end

  get '/api/items/buy' do
    content_type :json

    item = Item.by_id(params[:id].to_i)
    "no_such_item" if item.nil?

    user = User.by_name(params[:username])
    "no_such_user" if user.nil?
    "authentication_failed" unless user.password_matches?(params[:password])

    success, message = user.purchase(item, params[:quantity])

    "success" if success
    message
  end
end