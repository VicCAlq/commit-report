local pretty = require("pl.pretty")
local stringx = require("pl.stringx")
local utils = require("pl.utils")
local driver = require("luasql.sqlite3")
local f = string.format

---@Module db.lua
--- Module to create and manage SQLite3's databases for the project repositories.
--- Makes heavy use of the LuaSQL driver, to abstract the connections.
--- It works by first establishing the database's environment, then its connection,
--- and from this point onwards you can create statements that returns cursors.
---
--- Brief explanation of its methods below since the module doesn't
--- provide an interface that's LSP friendly:
---
--- # Environment creation:
--- `local env = assert(driver.sqlite3())`
--- # Connection creation:
--- `local conn = assert(env:connect(file_name: string, username: string?, password: string?)`
--- # Executing statements and getting the results:
--- `local cur = assert(conn:execute(sql_statement: string))`
---
--- Then we can iterate through the statement response with cursor methods.
--- Below are the more detailed explanations for each methor for the environment,
--- the connection and the cursor:
---
--- # Environment object (env)
--- `env:close() -> boolean` Success = true, Failure = false
--- `env:connect(file: string, username: Optional<string>, password: Optional<string>) -> Connection`
---
--- # Connection object (con)
--- `con:close() -> boolean` - Success = true, Failure = false
--- `con:execute(statement: string) -> Cursor | number` - Returns either a Cursor object or number of affected rows
--- The following three methods depend on transactions being implemented by the database
--- `con:commit() -> boolean` - Success = true, Failure = false
--- `con:rollback() -> boolean` - Success = true, Failure = false
--- `con:setautocommit(boolean) -> boolean` - Success = true, Failure = false
---
--- # Cursor object (cur)
--- `cur:close() -> boolean` Success = true, Failure = false
--- `cur:fetch(table: table, modestring: "n" | "a") -> table<[key: value]> | nil` - Gets the data
--- - `table` is the table to receive the data
--- - `modestring` how indices should be treated: "n" for numerical (default), "a" for alphanumerical
--- - If `fetch` reaches the last data, it'll return it and close the cursor since next data will be `nil`
--- `cur:getcolnames() -> table<string>` - List of column names
--- `cur:getcoltypes() -> table<string>` - List of column types
---
--- OBS: cur:fetch() isn't behaving as expected, replacing the whole table with the next
--- iteration instead of appending to the given table and returning it.

--- DataBase object class
---@class DB
---@field new function<string, string, string> Constructor
---@field open function<string> Opens the given database file
---@field close function Closes the database environment, connection and cursor
---@field open_table function<string> Opens the given table
---@field select function<string?, string?, string?> Runs a select statement on the given table
---@field insert function<string, table<table<string>>> Inserts the given items in the given table
---@field delete function<string, table<string>> Deletes the rows matching the given table and clauses
---@field drop_table function<string> Drops the given table
---@field create_table function<string, table<string>> Creates the given table
---@field format_values function<table<table<string>>> Returns the values as a string
---@field format_cols function<table<string>> Returns the column list as a string
---@field format_clauses function<table<string>> Returns the clause list as a string
---@field environment userdata Environment object
---@field connection userdata Connection object
---@field cursor userdata Cursor object
---@field rows table<any> Selected rows as a lua table
---@field tables table<string> List of tables for the database
---@field col_names table<string> List of column names for selected table
---@field col_types table<string> List of column types for selected table
local DB = {}

--- Instantiates the DataBase object
---@param db_file string Database file. If empty, it's automatically derived from owner and repository names
---@param owner string Owner name, it's the entity the repository is under, eg: github.com/owner
---@param repo_name string Repository name, as in gitlab.com/owner/repo_name
---@return table<any> obj The DataBase object
function DB:new(db_file, owner, repo_name)
  -- Constructor
  local obj = setmetatable({}, { __index = DB })

  obj.owner = owner
  obj.repo_name = repo_name
  obj.db_file = db_file or f("%s.%s.db", owner, repo_name)
  obj.environment, obj.connection, obj.tables = utils.unpack(self:open(db_file))
  ---@type userdata|nil Connection object if not nil
  obj.cursor = nil
  ---@type table<any>
  obj.rows = {}
  ---@type table<string>
  obj.col_names = {}
  ---@type table<string>
  obj.col_types = {}

  return obj
end

--- Opens the database connection, setting the Environment and Connection
--- objects, and the list of database tables, and returning them all.
---@param db_file string The database file name
---@return table<userdata, userdata, table<string>> res The Environment
---and Connection objects, and list of the DB's tables
function DB:open(db_file)
  local env = assert(driver.sqlite3())
  local con = assert(env:connect(f("./%s.db", db_file)))
  self.environment = env
  self.connection = con

  --- Gets the tables for the current database
  ---@diagnostic disable-next-line
  local cur = assert(con:execute([[
      SELECT name FROM sqlite_schema
      WHERE type='table' AND name NOT LIKE 'sqlite_%';
    ]]))

  local table_names = {}
  local row = cur:fetch({}, "n")

  while row do
    table.insert(table_names, f("%s", row[1]))
    row = cur:fetch(row, "n")
  end

  self.tables = table_names
  local res = { self.environment, self.connection, self.tables }
  return res
end

--- Safely closes the database connection
function DB:close()
  ---@diagnostic disable-next-line
  self.cursor:close()
  ---@diagnostic disable-next-line
  self.connection:close()
  ---@diagnostic disable-next-line
  self.environment:close()
end

--- Opens the referred table setting the database object's
--- column names and types and returning them all.
---@param table string The table name
---@return table<table<string>, table<string>> res The column names and types
function DB:open_table(table)
  ---@diagnostic disable-next-line
  self.cursor = assert(self.connection:execute(f("SELECT * FROM %s;", table)))
  ---@diagnostic disable-next-line
  local col_names = self.cursor:getcolnames()
  ---@diagnostic disable-next-line
  local col_types = self.cursor:getcoltypes()
  self.col_names = {}
  self.col_types = {}

  for i = 1, #col_names do
    self.col_names[i] = col_names[i]
  end
  for i = 1, #col_types do
    self.col_types[i] = col_types[i]
  end

  ---@diagnostic disable-next-line
  self.cursor:close()

  local res = { self.col_names, self.col_types }
  return res
end

--- Creates the given table
---@param tbl string Table name
---@param columns table<string> The columns to be created
---@return number affected_rows
function DB:create_table(tbl, columns)
  local cols = self:format_cols(columns)
  table.insert(self.tables, tbl)
  local db_table = tbl or self.tables[1]
  ---@diagnostic disable-next-line
  local res = assert(self.connection:execute(f("CREATE TABLE IF NOT EXISTS %s(%s);", db_table, cols)))

  return res
end

--- Drops the given table
---@param tbl string Table name
---@return number affected_rows
function DB:drop_table(tbl)
  local db_table = tbl or self.tables[1]
  for i, v in ipairs(self.tables) do
    if v == tbl then
      table.remove(self.tables, i)
    end
  end
  ---@diagnostic disable-next-line
  local res = assert(self.connection:execute(f("DROP TABLE %s;", db_table)))

  return res
end

--- Gets the result of the given SELECT statement as a Lua table, both
--- returning it and setting it to the internal `rows` field.
---@param tbl string The table to which the statement will be applied
---@param columns table<string>? The columns that will be fetched. Leave empty to select all
---@param clauses table<string>? The clauses to be given to the select statement. Leave empty for no clauses.
---@return table<any> rows The selected rows as a Lua table
function DB:select(tbl, columns, clauses)
  local db_table = tbl or self.tables[1]
  local cols = self:format_cols(columns) or "*"
  local cls = self:format_clauses(clauses) or ""

  ---@diagnostic disable-next-line
  self.cursor = assert(self.connection:execute(f("SELECT %s FROM %s %s;", cols, db_table, cls)))

  local selection = {}
  ---@diagnostic disable-next-line
  local row = self.cursor:fetch({}, "n")

  while row do
    local obj = {}
    for k, v in pairs(row) do
      obj[k] = v
    end
    table.insert(selection, obj)
    ---@diagnostic disable-next-line
    row = self.cursor:fetch(row, "n")
  end

  ---@diagnostic disable-next-line
  self.cursor:close()

  self.rows = selection
  return self.rows
end

--- Inserts new data (given as Lua tables) into the given db table
---@param tbl string Table name
---@param items table<table<string|number>> Items to be inserted
---@return number affected_rows
function DB:insert(tbl, items)
  local db_table = tbl or self.tables[1]
  assert(type(items) == "table")
  assert(type(items[1]) == "table")

  local values = self:format_values(items)
  local cols = self:format_cols(self.col_names)
  local statement = f(" INSERT INTO %s(%s) VALUES %s; ", db_table, cols, values)

  ---@diagnostic disable-next-line
  local affected_rows = assert(self.connection:execute(statement))

  return affected_rows
end

--- Deletes data corresponding to the given clauses (given as a table)
--- into the given db table
---@param tbl string Table name
---@param clauses table<string> Clauses to be parsed
---@return number affected_rows
function DB:delete(tbl, clauses)
  local db_table = tbl or self.tables[1]
  assert(type(clauses) == "table")
  assert(type(clauses[1]) == "string")

  local cls = self:format_clauses(clauses)
  local statement = f("DELETE FROM %s %s;", db_table, cls)

  ---@diagnostic disable-next-line
  local affected_rows = self.connection:execute(statement)

  return affected_rows
end

-- Formatter methods

--- Converts a table of items to a string of these items delimited
--- by parenthesis and separated by commas
---@param values table<table<string|number>>
---@return string formatted_values
function DB:format_values(values)
  assert(type(values) == "table")
  assert(type(values[1]) == "table")

  local formatted_values = ""

  for i, v in ipairs(values) do
    local value = '( "' .. stringx.join('", "', v) .. '" )'
    if i ~= #values then
      value = value .. ", "
    else
      value = value .. ";"
    end

    formatted_values = formatted_values .. value
  end

  return formatted_values
end

--- Converts a table of columns to a string of columns separated by commas
---@param columns table<string>?
---@return string cols
function DB:format_cols(columns)
  local cols = ""

  if columns ~= nil then
    for _, v in ipairs(columns) do
      cols = cols .. v .. ", "
    end
    cols = string.sub(cols, 1, -3)
  else
    cols = "*"
  end

  return cols
end

--- Converts a table of clauses to a string of clauses separated by commas
---@param clauses table<string>?
---@return string clause_str
function DB:format_clauses(clauses)
  local clause_str = ""

  if clauses ~= nil then
    for _, v in ipairs(clauses) do
      clause_str = clause_str .. " " .. v
    end
    clause_str = string.sub(clause_str, 2, -1)
  end

  return clause_str
end

-- ##############################          TESTS          ##############################

local function random_ut()
  local random_n = ""
  for _ = 1, 10 do
    random_n = random_n .. math.random(0, 9)
  end
  return random_n
end

local db = DB:new("aaa", "aaa", "aaa")

db:create_table("to_be_deleted", { "name VARCHAR(50)", "phone VARCHAR(20)" })
local c, d = utils.unpack(db:open_table("to_be_deleted"))
io.write("aaa.db tables > ")
pretty.dump(db.tables)
io.write("to_be_deleted column names > ")
pretty.dump(c)
io.write("to_be_deleted column types > ")
pretty.dump(d)

db:drop_table("to_be_deleted")

local a, b = utils.unpack(db:open_table("test_repo"))
io.write("aaa.db tables > ")
pretty.dump(db.tables)

io.write("test_repo column names > ")
pretty.dump(a)
io.write("test_repo column types > ")
pretty.dump(b)

io.write("Inserting data into test_repo > ")
local values = {
  {
    random_ut() .. "b723f5d3df90ab4db0e6d69830test",
    random_ut(),
    "VicTest",
    "vic@test.it",
    "test/thang",
    "2024-09-30 11:13:49.000",
    "test commit",
  },
  {
    random_ut() .. "b723f5d3df90ab4db0e6d69830aaaa",
    random_ut(),
    "VicTest",
    "vic@test.it",
    "test/thang",
    "2024-09-30 11:13:49.000",
    "test commit",
  },
}

db:insert("test_repo", values)

io.write("Data from table test_repo > ")
pretty.dump(db:select("test_repo"))

io.write("Selected data from table test_repo with some clauses > ")
pretty.dump(db:select("test_repo", { "unix_time", "author_name", "author_email" }, { "WHERE unix_time > 2727705629" }))

io.write("Deleting data for used VicTest from table test_repo > Affected rows: ")
print(db:delete("test_repo", { 'WHERE author_name = "VicTest"' }))
io.write("Data from table test_repo > ")
pretty.dump(db:select("test_repo"))

io.write("Data from table bbb > ")
pretty.dump(db:select("bbb"))

io.write("Value formatting test > ")
print(db:format_values(values))
io.write("Column formatting test > ")
print(db:format_cols({ "aaa", "bbb", "ccc" }))
io.write("Clause formatting test > ")
print(db:format_clauses({ "WHERE I test this", "AND I try that" }))

-- ##############################       END OF TESTS      ##############################

return DB
