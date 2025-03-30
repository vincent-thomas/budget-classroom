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

    db.execute('CREATE TABLE IF NOT EXISTS room_items (
                id TEXT PRIMARY KEY,
                room_id TEXT NOT NULL REFERENCES rooms(id),
                title TEXT NOT NULL,
                description TEXT NOT NULL,

                created_at DATETIME NOT NULL default current_timestamp,
                archived_at DATETIME
    )')

    db.execute('CREATE TABLE IF NOT EXISTS room_items_material (
                id TEXT PRIMARY KEY,
                room_item_id TEXT NOT NULL REFERENCES room_items(id),
                name TEXT NOT NULL,

                created_at DATETIME NOT NULL default current_timestamp,
                archived_at DATETIME
    )')

    # type:
    # 0 - pupil
    # 1 - teacher
    db.execute('CREATE TABLE IF NOT EXISTS room_items_comments (
                id TEXT PRIMARY KEY,
                room_item_id TEXT NOT NULL REFERENCES room_items(id),
                user_id TEXT NOT NULL,
                type INTEGER NOT NULL,
                content TEXT NOT NULL,

                created_at DATETIME NOT NULL default current_timestamp,
                archived_at DATETIME
    )')
    # user_id is null the invite has not been used
    # INVITE_STATE:
    # 0 - is pending
    # 1 - is accepted
    # 2 - is declined
    # 3 - is teacher
    db.execute('CREATE TABLE IF NOT EXISTS room_invites (
      id TEXT PRIMARY KEY,
      room_id TEXT NOT NULL REFERENCES rooms(id),
      user_id TEXT,
      invite_state INTEGER NOT NULL,

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
    teacher_id = SecureRandom.uuid

    db.execute('INSERT INTO teachers (id,username,email,hashed_password) VALUES (?,?,?,?)', [
      teacher_id,
      "teacher",
      "teacher@gmail.com",
      password
    ])

    pupil_id = SecureRandom.uuid


    db.execute('INSERT INTO pupils (id,username,email,hashed_password) VALUES (?,?,?,?)', [
      pupil_id,
      "pupil",
      "pupil@gmail.com",
      password
    ])

    room_id = SecureRandom.uuid

    db.execute('INSERT INTO rooms (id,name) VALUES (?,?)', [
      room_id,
      "Room 1"
    ])

    room_item_id = SecureRandom.uuid

    db.execute('INSERT INTO room_items (id,room_id,title,description) VALUES (?,?,?,?)', [
      room_item_id,
      room_id,
      "Item 1",
      "Description 1"
    ])

    db.execute('INSERT INTO room_items_material (id,room_item_id,name) VALUES (?,?,?)', [
      SecureRandom.uuid,
      room_item_id,
      "Material 1"
    ])

    db.execute("INSERT INTO room_invites (id,room_id,user_id,invite_state) VALUES (?,?,?,?)", [
      SecureRandom.uuid,
      room_id,
      pupil_id,
      1
    ])

    db.execute("INSERT INTO room_invites (id,room_id,user_id,invite_state) VALUES (?,?,?,?)", [
      SecureRandom.uuid,
      room_id,
      teacher_id,
      3 
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
