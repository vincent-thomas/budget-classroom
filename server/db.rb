
$global_db = nil

def db
  return $global_db if $global_db

  $global_db = SQLite3::Database.new("db/db.sqlite")
  $global_db.results_as_hash = true

  return $global_db
end
