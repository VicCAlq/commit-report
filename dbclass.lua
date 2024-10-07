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

--- DataBase object class
---@class DB
local DB = {}

--- Instantiates the DataBase object
---@param db_file string Database file. If empty, it's automatically derived from owner and repository names
---@param owner string Owner name, it's the entity the repository is under, eg: github.com/owner
---@param repo_name string Repository name, as in gitlab.com/owner/repo_name
---@return table<any> t The DataBase object
function DB:new(db_file, owner, repo_name)
  -- Constructor
  local t = setmetatable({}, { __index = DB })

  t.owner = owner
  t.repo_name = repo_name
  t.db_file = db_file or f("%s.%s.db", owner, repo_name)
  t.environment, t.connection, t.tables = utils.unpack(DB:open(db_file))
  ---@type userdata|nil Connection object if not nil
  t.cursor = nil
  ---@type table<any>
  t.rows = {}
  ---@type table<string>
  t.col_names = {}
  ---@type table<string>
  t.col_types = {}

  return t
end

--- Opens the database connection, setting the Environment and Connection
--- objects and returning them as well
---@param db_file string The database file name
---@return table<userdata> res The Environment object
function DB:open(db_file)
  local env = assert(driver.sqlite3())
  local con = assert(env:connect(f("./%s.db", db_file)))
  self.environment = env
  self.connection = con

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
  self.cursor:close()
  self.connection:close()
  self.environment:close()
end

function DB:open_table(table)
  local cur = assert(self.connection:execute(f("SELECT * FROM %s;", table)))
  self.cursor = cur
  local col_names = cur:getcolnames()
  local col_types = cur:getcoltypes()
  self.col_names = {}
  self.col_types = {}

  for i = 1, #col_names do
    self.col_names[i] = col_names[i]
  end
  for i = 1, #col_types do
    self.col_types[i] = col_types[i]
  end

  local res = { self.col_names, self.col_types, self.cursor }
  return res
end

function DB:select(tbl, columns, clauses)
  local db_table = tbl or self.tables[1]
  local cols = columns or "*"
  local cls = clauses or ""
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

local db = DB:new("aaa", "aaa", "aaa")
-- pretty.dump(db.tables)
local a, b = utils.unpack(db:open_table("test_repo"))
pretty.dump(a)
pretty.dump(db:select("test_repo"))
pretty.dump(db:select("bbb"))

return DB
