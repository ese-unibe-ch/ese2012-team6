require 'rubygems'
require 'sinatra'
require 'haml'
require 'app/models/university/student'
require 'app/controllers/main'
require 'app/controllers/authentication'

class App < Sinatra::Base

  use Authentication
  use Main

  enable :sessions
  set :public_folder, 'app/public'

  configure :development do
    University::Student.named( 'Erwann' ).save()
    University::Student.named( 'Joel' ).save()
    University::Student.named( 'Aaron').save()

    University::Student.all.each do |student|
      student.add( rand(6-1) + 1 )
    end
  end

end

# Now, run it
App.run!