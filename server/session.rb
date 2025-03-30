
require_relative './db.rb'

# Returns the session id
def internal_create_session(type, user_id)
  id = SecureRandom.uuid

  date = Time.now.to_i + 86_400

  db.execute("INSERT INTO sessions (id,user_id,type,valid_until) VALUES (?,?,?,?)", [id, user_id, type, date])

  return id
end

# Returns the session id
def create_teacher_session(user_id)
  return internal_create_session("teacher", user_id)
end

# Returns the session id
def create_pupil_session(user_id)
  return internal_create_session("pupil", user_id)
end

def validate_session(session_id)
  p "trying to validate session with id: #{session_id}"
  sessions = db.execute("SELECT * FROM sessions WHERE id=?", [session_id])

  p "nice sessions #{sessions}"


  if sessions.length == 0
    return nil
  end

  session = sessions[0]

  p "validate session with found id: #{session["id"]}"

  if session["valid_until"] < Time.now.to_i
    return nil
  end


  return session
end
