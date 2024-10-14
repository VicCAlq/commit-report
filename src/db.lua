local pretty = assert(require("pl.pretty"))
local driver = assert(require("luasql.sqlite3"))
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
local M = {}

---@alias Environment userdata Environment object
---@alias Connection userdata Connection object
---@alias Cursor userdata Cursor object

--- Converts a table of columns to a string of columns separated by commas
---@param columns table<string>?
---@return string cols
function M.format_cols(columns)
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
function M.format_clauses(clauses)
  local clause_str = ""

  if clauses ~= nil then
    for _, v in ipairs(clauses) do
      clause_str = clause_str .. v .. "; "
    end
    clause_str = string.sub(clause_str, 1, -2)
  end

  return clause_str
end

--- Opens a database connection and returns objects related to it
---@param repo_name string - Name of the repository's directory
---@param table string - Name of the table to look for
---@return Environment env Environment object
---@return Connection con Connection object
---@return Cursor cur Cursor object
---@return table<string> col_names Column names
---@return table<string> col_types Column types
function M.open(repo_name, table)
  table = table or "main"
  local env = assert(driver.sqlite3())
  local con = assert(env:connect(f("./%s.db", repo_name)))
  local cur = assert(con:execute(f("SELECT * from %s;", table)))
  local col_names = assert(cur:getcolnames())
  local col_types = assert(cur:getcoltypes())

  return env, con, cur, col_names, col_types
end

---@param con Connection Connection object
---@param table string Table name to be created
---@param fields table<string> List of fields for the new table
function M.create_table(con, table, fields)
  local field_defs = ""

  for _, v in ipairs(fields) do
    field_defs = f("%s%s, ", field_defs, v)
  end
  field_defs = string.sub(field_defs, 1, -3)

  ---@diagnostic disable-next-line
  local cur = assert(con:execute(f("CREATE TABLE IF NOT EXISTS %s ( %s );", table, field_defs)))

  return cur
end

--- Runs a statement on the given connection
---@param con Connection Connection object
---@param table string Table to receive the data
---@param columns table<string>? Column names to fetch
---@param clauses table<string>? List of clauses
---@return Cursor | number cur Cursor object or number of affected rows
function M.select(con, table, columns, clauses)
  local cols = M.format_cols(columns)
  local clause_list = M.format_clauses(clauses)

  ---@diagnostic disable-next-line
  local cur = assert(con:execute("SELECT " .. cols .. " FROM " .. table .. clause_list))
  return cur
end

--- Converts the given cursor to a list of row objects
---@param cur Cursor
---@return table rows
function M.parse_cursor(cur)
  ---@diagnostic disable-next-line
  local rows = cur:fetch({}, "a")
  local tbl = {}
  while rows do
    table.insert(tbl, rows)
    ---@diagnostic disable-next-line
    rows = cur:fetch(rows, "a")
  end
  return tbl
end

--- Safely closes the given database connection
--- Since more often than not the cursor will be closed upon reading
--- the last row, it's not uncommon for it to return `false`
---@param env Environment - Database's environment
---@param con Connection - Database's connection
---@param cur Cursor - Database's cursor
---@return table<boolean, boolean, boolean>
function M.close(env, con, cur)
  ---@diagnostic disable-next-line
  local is_cur_closed = cur:close()
  ---@diagnostic disable-next-line
  local is_con_closed = con:close()
  ---@diagnostic disable-next-line
  local is_env_closed = env:close()

  return { is_cur_closed, is_con_closed, is_env_closed }
end

local env, con, cur, col_names, col_types = M.open("../aaa", "test_repo")
pretty.dump(M.parse_cursor(cur))
pretty.dump(col_names)
pretty.dump(col_types)
pretty.dump(M.close(env, con, cur))

return M
