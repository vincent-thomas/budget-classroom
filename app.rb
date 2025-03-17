require 'date'
require 'securerandom'

require_relative './server/argon2'
require_relative './server/session'
require_relative './server/db'
require_relative './server/rooms.rb'


helpers do
  def render_component(template, locals = {})
    erb template, layout: false, views: "components", locals: locals
  end
end

class App < Sinatra::Application
    use Rack::Session::Cookie, key: 'rack.session',
      path: '/',
      secret: '4e22fb6f1568342b3cc46a3206086cf8aca44398651a1b1797b3fe727b05da58'


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

      if result.length == 0
        redirect "/auth/login"
      end

      valid_until = DateTime.strptime(result[0]["valid_until"], "%Y-%m-%d %H:%M:%S")

      if valid_until < DateTime.now()
        redirect "/auth/login"
      end

      return result[0]
    end



    # STUDENT API
    get "/api/rooms" do
      student = require_pupil_auth(session)

      status 200
    end


    # TEACHER API
    post "/api/rooms" do
      # TODO: teacher session id into database as teacher in classroom.

      name = params["name"]

      returned = db.execute("INSERT INTO rooms (name) VALUES (?)", [name])


      status 200
    end


    post "/api/rooms/:room_id/invites" do |room_id|
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

require_relative 'routes/flows-auth.rb'
require_relative 'routes/classes.rb'
