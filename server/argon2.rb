require "argon2"

# Returns: text
def hash_password(password)
  Argon2::Password.create(password)
end

# Returns: bool
def compare_password(text_password, hashed_password)
  Argon2::Password.verify_password(text_password, hashed_password)
end
