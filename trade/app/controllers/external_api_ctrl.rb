require 'json'
require 'rdiscount'
require_relative '../models/store/item'
require_relative '../models/store/trader'
require_relative '../models/store/user'
require_relative '../models/helpers/security/string_checker'

class ExternalApi < Sinatra::Application
  include Store
  include Security

  def check_id(id_string)
     !(id_string.nil? || id_string == "" || !StringChecker.is_numeric?(id_string) || id_string.to_i < 1)
  end

  get '/api/items' do
    content_type :json

    filter = params[:filter].strip

    if filter.nil? || filter = ""
      "INVALID_REQUEST"
    else
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
  end

  get '/api/items/description' do
    content_type :json

    if check_id(params[:id])
      id = params[:id].strip

      format = params[:format]
      format = format.strip if format

      item = Item.by_id(id.to_i)

      if item.nil?
        "NO_SUCH_ITEM"
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
    else
      "INVALID_REQUEST"
    end
  end

  get '/api/items/comments' do
    content_type :json

    if check_id(params[:id])
      id = params[:id].to_i
      item = Item.by_id(id)

      item.nil? ? "NO_SUCH_ITEM" : item.comments.to_json
    else
      "INVALID_REQUEST"
    end
  end

  post '/api/items/buy' do
    content_type :json

    item = Item.by_id(params[:item_id].to_i)
    "NO_SUCH_ITEM" if item.nil?

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