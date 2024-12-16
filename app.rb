require 'date'
require 'securerandom'

def create_session(user_id)
  session_id = SecureRandom.uuid()
  valid_until = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  db.execute("INSERT INTO sessions (id, user_id, valid_until) VALUES (?,?,?)", [session_id, user_id, valid_until])
  return session_id
end

class App < Sinatra::Base
    use Rack::Session::Cookie, key: 'session_id', path: '/', secret: "30b68d806425e1e933f8af04afb49a33f3d5961a9eb2ed8d7877134bc273e033"
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/db.sqlite")
      @db.results_as_hash = true

      return @db
    end

    def require_auth(session_id)
      p session_id
      result = db.execute("SELECT * FROM sessions JOIN users ON sessions.user_id = users.id WHERE sessions.id = ?;", [session_id])

      p result

      if result.length == 0
        redirect "/auth/login"
      end

      valid_until = DateTime.strptime(result[0]["valid_until"], "%Y-%m-%d %H:%M:%S")

      p valid_until, DateTime.now()

      if valid_until < DateTime.now()
        redirect "/auth/login"
      end

      return result[0]
    end
    def require_noauth(session_id, path)
      result = db.execute("SELECT * FROM sessions JOIN users ON sessions.user_id = users.id WHERE sessions.id = ?;", [session_id])

      if result.length != 0
        redirect path
      end
    end

    get '/lists' do
      @user = require_auth(session[:token])
      @lists = db.execute("SELECT * FROM todolists")
      erb(:"authed/lists" , layout: :"authed/layout")
    end
    post '/lists' do
      user = require_auth(session[:token])
      p user
      @lists = db.execute("INSERT INTO todolists (name, user_id) VALUES (?, ?)", [params["name"], user["user_id"]])
      redirect "/lists"
    end

    post '/lists/:list_id/delete' do |list_id|

      db.execute("DELETE FROM todolists WHERE id = ?", [list_id])
      redirect "/lists"
    end

    post '/lists/:list_id/todos' do |list_id|
      name = params["name"]

      db.execute("INSERT INTO todos (name, todolist_id) VALUES (?, ?)", [name, list_id])
      redirect "/lists/#{list_id}/todos"
    end

    get '/lists/:list_id/todos' do |list_id|
      name = params["name"]
      @user = require_auth(session[:token])

      @list_id = list_id

      @todos = db.execute('SELECT * from todos WHERE todolist_id = ? and done_at is NULL', [list_id])
      erb(:"authed/todos" , layout: :"authed/layout")
    end
    get '/lists/:list_id/todos/:todo_id' do | list_id, todo_id |
      @user = require_auth(session[:token])
      list = db.execute("SELECT * FROM todolists WHERE id = ? AND user_id = ?", [list_id.to_i, @user["user_id"]])

      if list.length == 0
        redirect "/lists"
      end

      todos = db.execute("SELECT * FROM todos WHERE todolist_id = ?", [list_id.to_i])

      if todos.length == 0
        redirect "/lists/#{list_id}/todos"
      end

      @todo = todos[0]
      @list = list[0]

      erb :"authed/one_todo" , layout: :"authed/layout"
    end

    post '/lists/:list_id/todos/:todo_id/delete' do | list_id, todo_id |
      @list_id = list_id
      @todo = db.execute('DELETE FROM todos WHERE id = ?', [todo_id])
      redirect "/lists/#{list_id}/todos"
    end

    post '/lists/:list_id/todos/:todo_id/update' do | list_id, todo_id |
      @list_id = list_id
      @todo = db.execute('UPDATE todos SET name = ? WHERE id = ?', [params["name"], todo_id])
      redirect "/lists/#{list_id}/todos/#{todo_id}"
    end

    post '/lists/:list_id/todos/:todo_id/done' do | list_id, todo_id |
      db.execute('UPDATE todos SET done_at = ? WHERE id = ?', [DateTime.now.strftime("%Y-%m-%d %H:%M:%S"), todo_id])
      redirect "/lists/#{list_id}/todos"
    end

    post '/api/account' do

      email = params["email"]
      password = params["password"]
    end



   get '/auth/login' do
     erb(:"auth/login")
   end
   get '/auth/register' do
    erb(:"auth/register")
   end
    post '/api/auth/login' do
      username = params[:username]
      password = params[:password]

      user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

      if user == nil
        redirect "/auth/login?wrong=true"
      end

      p user["hashed_password"], password, username

      hashed_password = user["hashed_password"]
      p hashed_password

      valid_password = Argon2::Password.verify_password(password, hashed_password)

      if !valid_password
        redirect "/auth/login?wrong=true"
      end

      session[:token] = create_session(user["id"])

      redirect "/lists"
    end
    post '/api/auth/register' do
      username = params[:username]
      password = params[:password]
      p password
      hashed_password = Argon2::Password.create(password)

      user_id = SecureRandom.uuid()

      result = db.execute("INSERT INTO users (id, username, hashed_password) VALUES (?,?,?)", [user_id, username, hashed_password]).first
      p user_id

      session[:token] = create_session(user_id)

      redirect "/lists"
    end
end


