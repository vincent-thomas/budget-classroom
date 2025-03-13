require 'sinatra'
require 'sinatra/namespace'
require 'securerandom'

require_relative '../server/session.rb'

def get_classes_pupil(session_id, room_id)
  puts room_id, session_id
  erb :pupil_classes
end


def get_class_pupil(session_id, room_id)
  result = db.execute("SELECT * FROM rooms WHERE id = ?", [room_id])

  if result.length == 0
    status 404
    return "Room not found"
  end

  @room = result[0]
  erb :pupil_class
end

class App < Sinatra::Application
  namespace "/classes" do
    get "/create" do
      this_session = validate_session(session[:id].to_s)

      if this_session == nil || this_session["type"] != "teacher"
        session.clear()
        redirect "/flows/teacher-login"
      end

      erb :create_class
    end
    post "/create" do
      this_session = validate_session(session[:id].to_s)

      if this_session == nil || this_session["type"] != "teacher"
        session.clear()
        redirect "/flows/teacher-login"
      end

      class_name = params["class_name"]

      if class_name == nil || class_name == "" || class_name.length > 20
        status 400
        return "Class name is invalid"
      end

      room_id = SecureRandom.uuid

      db.execute("INSERT INTO rooms (id, name) VALUES (?,?)", [room_id, class_name])

      room_invite_id = SecureRandom.uuid

      db.execute("INSERT INTO room_invites (id, room_id, user_id, invite_state) VALUES (?, ?, ?, ?)", [room_invite_id, room_id, this_session["user_id"], 3])

      redirect "/classes/#{room_id}"
    end

    get "/:room_id" do |room_id|
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
        redirect "/flows/teacher-login"
      end

      if this_session["type"] == "pupil"
        return get_class_pupil(this_session[:id].to_s, room_id)
      end

      status 200

      # room = db.execute("SELECT * FROM rooms WHERE id = ?", [room_id])
      #
      # if room.length == 0
      #   status 404
      #   return "Room not found"
      # end
      #
      # room = room[0]
      #
      # erb :room, locals: {room: room}
    end



    get "" do

      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
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
        redirect "/flows/pupil-login"
      end
    end

    get "/new" do
      erb :new
    end
  end
end
