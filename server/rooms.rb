require "securerandom"
require_relative "../server/db"

def create_teacher_room(teacher_id, room_name)
  room_id = SecureRandom.uuid()
  db.execute("INSERT INTO rooms (id, name) VALUES (?, ?)", [room_id, room_name])

  room_invite_id = SecureRandom.uuid()

  db.execute("INSERT INTO room_invites (id, room_id, user_id, is_teacher)", [room_invite_id, room_id, teacher_id, true])

  [room_id, room_invite_id]
end

# This can be used for both teachers and student sessions.
def get_user_rooms(user_id)

  room_invites = db.execute("SELECT * FROM room_invites WHERE user_id = ?", [user_id])

  p "invites", room_invites

  # TODO:

end

