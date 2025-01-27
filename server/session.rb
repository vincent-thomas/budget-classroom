
def internal_create_session(type, user_id)
  created_at = Time.now
  return {
    "user_id" => user_id,
    "type" => type,
    "created_at" => created_at,
    "valid_until" => created_at + 86_400
  }
end

def create_teacher_session(user_id)
  return internal_create_session("teacher", user_id)
end

def internal_validate_session(type, session)
  if session == session
    return nil
  end
  if type != nil
    if session["type"] != type
      return nil
    end
  end

  if session["valid_until"] < Time.now
    return nil
  end

  return user_id
end

# Returns:
# - nil: if not valid,
# - user_id (text): if valid
def validate_teacher_session(session)
  internal_validate_session("teacher", session)
end

def validate_pupil_session(session)
  internal_validate_session("pupil", session)
end

def validate_any_session(session)
  internal_validate_session(nil, session)
end
