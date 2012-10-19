require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')

# Handles all requests concerning user registration
class Organization < Sinatra::Application

  # Shows registration form
  get '/organizations' do
    haml :all_organizations
  end

end