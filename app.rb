require 'date'
class App < Sinatra::Base
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/db.sqlite")
      @db.results_as_hash = true

      return @db
    end

    def require_auth(session_id)
      result = db.execute("SELECT * FROM sessions WHERE id = ? JOIN users ON sessions.user_id = users.id;", [session_id])

      p result

      if result.length == 0
        redirect "/auth/login"
      end
    end

    get '/lists' do
      require_auth("testing")
      @lists = db.execute("SELECT * FROM todolists")
      erb(:"lists")
    end
    post '/lists' do

      @lists = db.execute("INSERT INTO todolists (name) VALUES (?)", [params["name"]])
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

      @list_id = list_id

      @todos = db.execute('SELECT * from todos WHERE todolist_id = ? and done_at is NULL', [list_id])
      erb(:"todos")
    end
    get '/lists/:list_id/todos/:todo_id' do | list_id, todo_id |
      list = db.execute("SELECT * FROM todolists WHERE id = ?", [list_id.to_i])
      todos = db.execute('SELECT * FROM todos WHERE id = ?', [todo_id.to_i])

      if list.length == 0
        redirect "/lists"
      end

      if todos.length == 0
        redirect "/lists/#{list_id}/todos"
      end

      @todo = todos[0]
      @list = list[0]

      erb(:"one_todo")
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

      p email, password


    end

end
