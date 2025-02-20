require 'sqlite3'
require 'securerandom'
require_relative '../server/argon2'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS rooms')
    db.execute('DROP TABLE IF EXISTS room_invites')
    db.execute('DROP TABLE IF EXISTS pupils')
    db.execute('DROP TABLE IF EXISTS teachers')
    db.execute('DROP TABLE IF EXISTS sessions')
  end

  def self.create_tables

    db.execute('CREATE TABLE IF NOT EXISTS rooms (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,

                created_at DATETIME NOT NULL default current_timestamp,
                archived_at DATETIME
    )')

    # user_id is null the invite has not been used
    db.execute('CREATE TABLE IF NOT EXISTS room_invites (
      id INTEGER PRIMARY KEY,
      room_id TEXT NOT NULL REFERENCES rooms(id),
      user_id TEXT,
      is_teacher INTEGER NOT NULL,

      created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute('CREATE TABLE IF NOT EXISTS teachers (
      id TEXT PRIMARY KEY,

      username TEXT NOT NULL,
      email TEXT NOT NULL,
      hashed_password TEXT NOT NULL,

      created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute('CREATE TABLE IF NOT EXISTS pupils (
      id TEXT PRIMARY KEY,

      username TEXT NOT NULL,
      email TEXT NOT NULL,
      hashed_password TEXT NOT NULL,

      created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute("CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      TEXT INTEGER REFERENCES users(id),

      type TEXT CHECK( type IN ('teacher','pupil') ) NOT NULL,

      created_at DATETIME NOT NULL default current_timestamp,
      valid_until INTEGER NOT NULL
    )")
  end

  def self.populate_tables

    password = hash_password("password123")

    db.execute('INSERT INTO teachers (id,username,email,hashed_password) VALUES (?,?,?,?)', [
      SecureRandom.uuid,
      "teacher",
      "teacher@gmail.com",
      password
    ])

    db.execute('INSERT INTO pupils (id,username,email,hashed_password) VALUES (?,?,?,?)', [
      SecureRandom.uuid,
      "pupil",
      "pupil@gmail.com",
      password
    ])
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/db.sqlite')
    @db.results_as_hash = true
    @db
  end
end


Seeder.seed!
