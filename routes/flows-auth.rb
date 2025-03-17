require 'sinatra'
require 'sinatra/namespace'

require_relative '../server/session.rb'

class App < Sinatra::Application

  namespace "/flows" do
    get "/pupil-login" do

      this = validate_session(session[:id])

      if this == nil
        erb :"flows/pupil-login"
      elsif this["type"] == "teacher" || this["type"] == "pupil"
        redirect "/classes"
      end
    end

    post "/pupil-login" do
      this = validate_session(session[:id])

      if this != nil
        if this[:type] == "pupil" or this[:type] == "teacher"
          redirect "/classes"
        end
      end

      p "existing session: #{this}"

      email = params[:email]
      password = params[:password]

      teachers = db.execute("SELECT * FROM pupils WHERE email = ?", [email])

      if teachers.length == 0
        puts "REDIRECT 3"
        redirect "/flows/pupil-login?wrong_credentials=true"
      end

      teacher = teachers[0]

      is_valid_password = compare_password(password, teacher["hashed_password"])
      p "is_valid_password: #{is_valid_password}"

      if !is_valid_password
        puts "REDICT 5"
        redirect "/flows/pupil-login?wrong_credentials=true"
      end

      session_id = create_teacher_session(teacher["id"])

      session[:id] = session_id

      session[:type] = "pupil"
      redirect "/classes"
    end













    get "/teacher-login" do

      this = validate_session(session[:id])

      if this == nil
        erb :"flows/teacher-login"
      elsif this["type"] == "teacher" || this["type"] == "pupil"
        redirect "/classes"
      end
    end

    post "/teacher-login" do
      this = validate_session(session[:id])

      if this != nil
        if this[:type] == "pupil" || this[:type] == "teacher"
          redirect "/classes"
        end
      end

      email = params[:email]
      password = params[:password]

      teachers = db.execute("SELECT * FROM teachers WHERE email = ?", [email])

      if teachers.length == 0
        redirect "/flows/teacher-login?wrong_credentials=true"
      end

      teacher = teachers[0]

      is_valid_password = compare_password(password, teacher["hashed_password"])
      p "is_valid_password: #{is_valid_password}"

      if !is_valid_password
        redirect "/flows/teacher-login?wrong_credentials=true"
      end

      p "TEACJER ID ", teacher["id"]

      session_id = create_teacher_session(teacher["id"])

      session[:id] = session_id

      session[:type] = "teacher"
      p "SESSION"
      p session
      redirect "/classes"
    end
  end
end
