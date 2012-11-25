require 'json'
require 'orderedhash'

module Api
  class ApiResponse
    attr_accessor :result, :status

    def initialize
      self.result = nil
      self.status = ""
    end

    def self.success(result, status = "OK")
      response = ApiResponse.new
      response.result = result
      response.status = status
      response.to_json
    end

    def self.invalid
      response = ApiResponse.new
      response.result = nil
      response.status = "INVALID_REQUEST"
      response.to_json
    end

    def self.failed(reason)
      response = ApiResponse.new
      response.result = nil
      response.status = reason
      response.to_json
    end

    def to_json(*opt)
      hash = OrderedHash.new
      hash[:result] = self.result
      hash[:status] = self.status
      hash.to_json(*opt)
    end
  end
end
