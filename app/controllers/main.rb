require 'tilt/haml'
require '../../app/models/store/user'
require '../../app/models/store/item'

class Main < Sinatra::Application

  get "/" do

    redirect '/login' unless session[:name]

    haml :list_students, :locals => { :time => Time.now ,
                                      :students => University::Student.all,
                                      :current_name => session[:name] }
  end

end