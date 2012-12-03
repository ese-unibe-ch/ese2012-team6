require 'rdiscount'
require_relative '../models/store/item'
require_relative '../models/store/trader'
require_relative '../models/store/user'
require_relative '../models/helpers/security/string_checker'
require_relative '../models/helpers/exceptions/trade_error'
require_relative '../models/api/api_response'

class ExternalApi < Sinatra::Application
  include Store
  include Security
  include Api

  def check_param(param)
    param != nil && param != ""
  end

  def check_id(id_string)
     check_param(id_string) && StringChecker.is_numeric?(id_string) && id_string.to_i > 0
  end

  def check_auth_token(token_string)
    check_param(token_string) && StringChecker.matches_regex?(token_string, /.+,.+/)
  end

  get '/api/items' do
    content_type :json

    if check_param(params[:filter])
      filter = params[:filter].strip

      case filter
        when "none"
          items = Item.allFixed
          ApiResponse.success(items)
        when "active"
          items = Item.allFixed.select {|item| item.state == :active}
          ApiResponse.success(items)
        when "inactive"
          items = Item.allFixed.select {|item| item.state == :inactive}
          ApiResponse.success(items)
        else
          ApiResponse.invalid
      end
    else
      ApiResponse.invalid
    end
  end

  get '/api/items/description' do
    content_type :json

    if check_id(params[:id])
      id = params[:id].strip

      format = params[:format]
      item = Item.by_id(id.to_i)

      if item.nil?
        ApiResponse.failed("NO_SUCH_ITEM")
      else
        case format
          when "text"
            ApiResponse.success(item.description)
          when "html"
            ApiResponse.success(RDiscount.new(item.description, :smart, :filter_html).to_html)
          else
            ApiResponse.success(item.description)
        end
      end
    else
      ApiResponse.invalid
    end
  end

  get '/api/items/comments' do
    content_type :json

    if check_id(params[:id])
      id = params[:id].to_i
      item = Item.by_id(id)

      item.nil? ? ApiResponse.failed("NO_SUCH_ITEM") : ApiResponse.success(item.comments)
    else
      ApiResponse.invalid
    end
  end

  post '/api/items/buy' do
    content_type :json
    if check_id(params[:item_id]) && check_auth_token(params[:auth_token]) && check_param(params[:quantity]) && StringChecker.is_numeric?(params[:quantity])
      auth_token = params[:auth_token].split(",")
      username = auth_token[0].strip
      password = auth_token[1].strip

      user = User.by_name(username)
      if user && user.password_matches?(password)
        item = Item.by_id(params[:item_id].to_i)

        if item
          if user.can_buy?(item)
            begin
              purchase = user.purchase(item, params[:quantity].to_i)
              ApiResponse.success(purchase.item)
            rescue Exceptions::TradeError => error
              ApiResponse.failed(error.message)
            end
          else
            ApiResponse.failed("CANNOT_BUY_ITEM")
          end
        else
          ApiResponse.failed("NO_SUCH_ITEM")
        end
      else
        ApiResponse.failed("AUTHENTICATION_FAILED")
      end
    else
      ApiResponse.invalid
    end
  end
end