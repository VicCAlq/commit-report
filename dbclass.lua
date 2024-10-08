local pretty = require("pl.pretty")
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
  obj.environment, obj.connection, obj.tables = utils.unpack(DB:open(db_file))
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
  local cur = assert(self.connection:execute(f("SELECT %s FROM %s %s;", cols, db_table, cls)))

  local selection = {}
  local row = cur:fetch({}, "n")

  while row do
    local obj = {}
    for k, v in pairs(row) do
      obj[k] = v
    end
    table.insert(selection, obj)
    row = cur:fetch(row, "n")
  end

  self.rows = selection
  return self.rows
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
      clause_str = clause_str .. v .. "; "
    end
    clause_str = string.sub(clause_str, 1, -2)
  end

  return clause_str
end

-- ##############################          TESTS          ##############################

local db = DB:new("aaa", "aaa", "aaa")
-- pretty.dump(db.tables)
local a, b = utils.unpack(db:open_table("test_repo"))
io.write("aaa.db tables > ")
pretty.dump(db.tables)
io.write("test_repo column names > ")
pretty.dump(a)
io.write("test_repo column types > ")
pretty.dump(b)
io.write("Data from table test_repo > ")
pretty.dump(db:select("test_repo"))
io.write("Data from table bbb > ")
pretty.dump(db:select("bbb"))

-- ##############################       END OF TESTS      ##############################

return DB
