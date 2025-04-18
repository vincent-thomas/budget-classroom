require 'sinatra'
require 'sinatra/namespace'

require_relative '../server/session.rb'

class App < Sinatra::Application
  get "/profile" do
    erb :profile
  end
  namespace "/flows" do
    get "/logout" do
      session.clear()
      redirect "/"
    end


    get "/pupil-login" do
      this = validate_session(session[:id])

      if this != nil && (this["type"] == "teacher" || this["type"] == "pupil")
        redirect "/classes"
      end
      erb :"flows/pupil-login"
    end

    post "/pupil-login" do
      this = validate_session(session[:id])

      if this != nil && (this["type"] == "teacher" || this["type"] == "pupil")
        redirect "/classes"
      end

      email = params[:email]
      password = params[:password]

      teachers = db.execute("SELECT * FROM pupils WHERE email = ?", [email])

      if teachers.length == 0
        redirect "/flows/pupil-login?wrong_credentials=true"
      end

      teacher = teachers[0]

      is_valid_password = compare_password(password, teacher["hashed_password"])
      p "is_valid_password: #{is_valid_password}"

      if !is_valid_password
        redirect "/flows/pupil-login?wrong_credentials=true"
      end

      session_id = create_pupil_session(teacher["id"])

      session[:id] = session_id

      session[:type] = "pupil"
      redirect "/classes"
    end



    get "/teacher-login" do
      this = validate_session(session[:id])

      if this != nil && (this["type"] == "teacher" || this["type"] == "pupil")
        redirect "/classes"
      end
      erb :"flows/teacher-login"
    end

    post "/teacher-login" do
      this = validate_session(session[:id])

      if this != nil && (this["type"] == "teacher" || this["type"] == "pupil")
        redirect "/classes"
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

      session_id = create_teacher_session(teacher["id"])

      session[:id] = session_id

      p "nice session id at login: #{session[:id]}"
      session[:type] = "teacher"
      redirect "/classes"
    end
  end
end
