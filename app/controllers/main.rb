require 'haml'
require 'models/store/user'
require 'models/store/item'

class Main < Sinatra::Application

  get "/" do

    redirect '/login' unless session[:name]

    haml :list_students, :locals => { :time => Time.now ,
                                      :current_name => session[:name] }
  end

end