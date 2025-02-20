
require_relative './db.rb'

def internal_create_session(type, user_id)
  id = SecureRandom.uuid

  date = Time.now.to_i + 86_400

  p date

  db.execute("INSERT INTO sessions (id,user_id,type,valid_until) VALUES (?,?,?,?)", [id,user_id, type, date])
end

def create_teacher_session(user_id)
  return internal_create_session("teacher", user_id)
end

def validate_session(session_id)
  sessions = db.execute("SELECT * FROM sessions WHERE id=?", [session_id])

  if sessions.length == 0
    return nil
  end

  session = sessions[0]

  if session["valid_until"] < Time.now
    return nil
  end

  return session
end
