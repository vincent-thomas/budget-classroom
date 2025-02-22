require 'sinatra'
require 'sinatra/namespace'

require_relative '../server/session.rb'

def get_classes_pupil(session_id)
  erb :pupil_classes
end

def get_classes_teacher(session_id)
  erb :teacher_classes
end

class App < Sinatra::Application
  namespace "/classes" do
    get "" do

      this_session = validate_session(session[:id].to_s)
      user_type = this_session["type"]

      case user_type
      when "teacher"
        get_classes_teacher(session[:id].to_s)
      when "pupil"
        get_classes_pupil(session[:id].to_s)
      else
        session.clear()
        redirect "/flows/pupil-login"
      end
    end

    get "/new" do
      erb :new
    end
  end
end
