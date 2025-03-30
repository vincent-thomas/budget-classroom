require 'sinatra'
require 'sinatra/namespace'
require 'securerandom'

require_relative '../server/session.rb'

def get_classes_pupil(user_id)
  # Get all rooms and their invite states for this pupil
  @rooms = db.execute("""
    SELECT rooms.*, room_invites.invite_state as room_invite 
    FROM rooms
    LEFT JOIN room_invites ON rooms.id = room_invites.room_id 
      AND room_invites.user_id = ?
    WHERE rooms.archived_at IS NULL
    ORDER BY rooms.created_at DESC
  """, [user_id])

  erb :pupil_classes
end

def get_classes_teacher(user_id)

  # Get all rooms owned by this teacher (where they have invite_state = 3)
  @classes = db.execute("""
    SELECT rooms.*, teachers.username as teacher_name 
    FROM rooms
    JOIN room_invites ON rooms.id = room_invites.room_id 
    JOIN teachers ON room_invites.user_id = teachers.id
    WHERE room_invites.user_id = ? 
    AND room_invites.invite_state = 3 
    AND rooms.archived_at IS NULL
    ORDER BY rooms.created_at DESC
  """, [user_id])

  erb :teacher_classes
end

def get_class_pupil(user_id, room_id)
  result = db.execute("""
    SELECT rooms.*, room_invites.invite_state 
    FROM rooms
    LEFT JOIN room_invites ON rooms.id = room_invites.room_id 
      AND room_invites.user_id = $1
    WHERE rooms.id = $2 AND room_invites.invite_state = 1
  """, [user_id, room_id])

  if result.length == 0
    status 403
    return "You do not have access to this room"
  end

  if result.length == 0
    status 404
    return "Room not found"
  end

  @room_items = db.execute("""
    SELECT room_items.*, 
           room_items_material.name as material_name
    FROM room_items 
    LEFT JOIN room_items_material ON 
      room_items.id = room_items_material.room_item_id
    WHERE room_items.room_id = ? AND 
          room_items.archived_at IS NULL
    ORDER BY room_items.created_at DESC
  """, [room_id])
  p @room_items

  @room = result[0]
  erb :pupil_class
end

def get_class_teacher(session_id, room_id)
  result = db.execute("SELECT * FROM rooms WHERE id = ?", [room_id])

  if result.length == 0
    status 404
    return "Room not found"
  end

  # Get all room items with their materials
  @room_items = db.execute("""
    SELECT room_items.*, 
           room_items_material.name as material_name
    FROM room_items 
    LEFT JOIN room_items_material ON 
      room_items.id = room_items_material.room_item_id
    WHERE room_items.room_id = ? AND 
          room_items.archived_at IS NULL
    ORDER BY room_items.created_at DESC
  """, [room_id])

  # Verify teacher has access to this room
  teacher_access = db.execute("""
    SELECT * FROM room_invites 
    WHERE room_id = ? AND user_id = ? AND invite_state = 3
  """, [room_id, session["user_id"]])

  if teacher_access.length == 0
    status 403
    return "Unauthorized"
  end

  @room = result[0]
  erb :teacher_class
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

    get "/new" do
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
        redirect "/flows/pupil-login"
      end
      user_type = this_session["type"]

      if user_type == "teacher"
        erb :new
      end

      redirect "/classes"
    end

    get "/:room_id" do |room_id|
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
        redirect "/flows/teacher-login"
      end


      if this_session["type"] == "pupil"
        return get_class_pupil(this_session["user_id"], room_id)
      elsif this_session["type"] == "teacher" 
        return get_class_teacher(this_session["user_id"], room_id)
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

    get "/:room_id/items/:item_id" do |room_id, item_id|
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
        redirect "/flows/pupil-login"
      end

      # Get the room item
      room_item = db.execute("SELECT * FROM room_items WHERE id = ? AND room_id = ?", [item_id, room_id])

      if room_item.length == 0
        status 404
        return "Item not found"
      end

      room_item = room_item[0]

      # Get any associated material
      material = db.execute("SELECT * FROM room_items_material WHERE room_item_id = ?", [item_id])
      room_item["material_name"] = material[0]["name"] if material.length > 0

      # Get any comments
      comments = db.execute("SELECT * FROM room_items_comments WHERE room_item_id = ?", [item_id])
      room_item["comments"] = comments

      erb :pupil_item, locals: {room_id: room_id, item: room_item}
    end

    post "/:room_id/items/:item_id/comment" do |room_id, item_id|
      this_session = validate_session(session[:id].to_s)

      if this_session == nil
        session.clear()
        redirect "/flows/pupil-login"
      end

      # Check if user has access to this room
      user_id = this_session["user_id"]
      user_type = this_session["type"]
      
      room_access = if user_type == "teacher"
        # Check if teacher owns room
        db.execute("SELECT * FROM rooms WHERE id = ?", [room_id]).length > 0
      else
        # Check if pupil has accepted invite
        db.execute(
          "SELECT * FROM room_invites WHERE room_id = ? AND user_id = ? AND invite_state = 1", 
          [room_id, user_id]
        ).length > 0
      end

      unless room_access
        status 403
        return "You don't have access to this room"
      end

      # Validate content exists
      content = params[:content]
      if !content || content.strip.empty?
        status 400
        return "Comment content is required"
      end

      # Create comment
      comment_id = SecureRandom.uuid
      comment_type = user_type == "teacher" ? 1 : 0

      db.execute(
        "INSERT INTO room_items_comments (id, room_item_id, user_id, type, content) VALUES (?, ?, ?, ?, ?)",
        [comment_id, item_id, user_id, comment_type, content]
      )

      redirect "/classes/#{room_id}/items/#{item_id}"
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
        get_classes_teacher(this_session["user_id"].to_s)
      when "pupil"
        get_classes_pupil(this_session["user_id"].to_s)
      else
        session.clear()
        redirect "/flows/pupil-login"
      end
    end


  end
end
