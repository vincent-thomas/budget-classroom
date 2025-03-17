require 'sinatra'
require 'sinatra/namespace'

require_relative '../server/db'
require_relative '../server/session'

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

      if this_session == nil
        puts "REDIRECT 1"
        redirect "/flows/pupil-login"
      end
      user_type = this_session["type"]

      case user_type
      when "teacher"
        get_classes_teacher(session[:id].to_s)
      when "pupil"
        get_classes_pupil(session[:id].to_s)
      else
        session.clear()
        puts "REDIRECT 2"
        redirect "/flows/pupil-login"
      end
    end

    get "/:class_id" do |id|
      @class_id = id
      @posts = [
        {
          "post_id" => "nice_post",
          "user_id" => "teacher_id",
          "type" => "teacher",
          "name" => "very nice upgift"
        }
      ]

      erb :pupil_class
    end

    get "/new" do
      erb :new
    end
  end

  namespace "/api/classes" do
    get "" do
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        status 401
        return "Unauthorized"
      end

      p "SESSION", this_session

      user_id = this_session["user_id"]

      get_user_rooms(user_id)

      status 200
    end
  end
end
