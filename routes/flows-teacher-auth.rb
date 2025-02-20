require 'sinatra'
require 'sinatra/namespace'

require_relative '../server/session.rb'

class App < Sinatra::Application

  namespace "/flows" do
    get "/teacher-login" do

      this = validate_session(session[:id])
      if this != nil
        session = nil
      end
      p this
      erb :"flows/teacher-login"

    end
  end
end
