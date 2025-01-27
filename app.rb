require 'date'
require 'securerandom'

require_relative './server/argon2'
require_relative './server/session'


class App < Sinatra::Base
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/db.sqlite")
      @db.results_as_hash = true

      return @db
    end

    def require_pupil_auth(session)

      if session["type"] == "teacher"
        session = nil
        redirect "/flows/teacher-login"
      end

      if session["user_id"] == nil
        session = nil
        redirect "/auth/login"
      end

      result = db.execute("SELECT * FROM sessions JOIN pupils ON pupil_sessions.user_id = users.id WHERE pupil_sessions.id = ?;", [session_id])

      p result

      if result.length == 0
        redirect "/auth/login"
      end

      valid_until = DateTime.strptime(result[0]["valid_until"], "%Y-%m-%d %H:%M:%S")

      p valid_until, DateTime.now()

      if valid_until < DateTime.now()
        redirect "/auth/login"
      end

      return result[0]
    end

    get "/classes" do
      this = validate_any_session(session)

      if this == nil
        redirect "/flows/teacher-login"
      end

      p this
      return "nice"
    end

    get "/flows/teacher-login" do
      this = validate_teacher_session(session)
      if this != nil
        session = nil
      end
      erb :"flows/teacher-login"
    end

    post "/flows/teacher-login" do

      email = params[:email]
      password = params[:password]

      teachers = db.execute("SELECT * FROM teachers WHERE email = ?", [email])


      if teachers.length == 0
        redirect "/flows/teacher-login?wrong_credentials=true"
      end


      teacher = teachers[0]
      is_valid_password = compare_password(password, teacher["hashed_password"])

      p is_valid_password

      if !is_valid_password
        redirect "/flows/teacher-login?wrong_credentials=true"
      end
      p session
      session_data = create_teacher_session(teacher["id"])
      session[:user_id] = session_data[:user_id]
      session[:type] = session_data[:type]
      redirect "/classes"
    end

    # STUDENT API
    get "/api/rooms" do
      student = require_pupil_auth(session)

      p student
      # # TODO: teacher session id into database as teacher in classroom.
      # p params
      #
      # name = params["name"]
      #
      # returned = db.execute("SELECT FROM rooms *", [name])
      #
      # p returned
      #
      # status 200
    end


    # TEACHER API
    post "/api/rooms" do
      # TODO: teacher session id into database as teacher in classroom.
      p params

      name = params["name"]

      returned = db.execute("INSERT INTO rooms (name) VALUES (?)", [name])

      p returned

      status 200
    end

    post "/api/rooms/:room_id/invites" do
      room_id = params.room_id

      body = JSON.parse(request.body.read)

      classroom_id = body["classroom_id"]
      pupil_id = body["pupil_id"]

      is_teacher = body["is_teacher"]

      returned = db.execute("INSERT INTO room_invite (room_id, user_id, is_teacher) VALUES (?, ?, ?)", [room_id, user_id, is_teacher])
      status 200
    end

    delete "/api/rooms/:room_id/invites/:invite_id" do
      # TODO
      #
      raise "IMPLEMENT_THIS"
    end
end


