require 'sqlite3'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS todolists')
    db.execute('DROP TABLE IF EXISTS todos')
  end

  def self.create_tables

    db.execute('CREATE TABLE IF NOT EXISTS todolists (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id REFERENCES NOT NULL users(id),
                name TEXT NOT NULL,
                created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute('CREATE TABLE IF NOT EXISTS todos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                todolist_id INTEGER NOT NULL REFERENCES todolists(id),
                name TEXT NOT NULL,
                done_at DATETIME,
                priority INTEGER,
                deadline_at DATETIME,
                created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute('CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      username TEXT NOT NULL,
      hashed_password TEXT NOT NULL,

      created_at DATETIME NOT NULL default current_timestamp
    )')

    db.execute('CREATE TABLE IF NOT EXISTS sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER REFERENCES users(id),

      created_at DATETIME NOT NULL default current_timestamp,
      valid_until DATETIME NOT NULL
    )')
  end

  def self.populate_tables
    # db.execute('INSERT INTO fruits (name, tastiness, description) VALUES ("Äpple",   7, "En rund frukt som finns i många olika färger.")')
    # db.execute('INSERT INTO fruits (name, tastiness, description) VALUES ("Päron",    6, "En nästan rund, men lite avläng, frukt. Oftast mjukt fruktkött.")')
    # db.execute('INSERT INTO fruits (name, tastiness, description) VALUES ("Banan",  4, "En avlång gul frukt.")')
    # db.execute('INSERT INTO fruits (name, tastiness, description) VALUES ("Mango",  9, "En god (kanske) frukt med jobbig kärna i mitten.")')
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
