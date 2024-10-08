local pretty = require("pl.pretty")
local driver = require("luasql.sqlite3")
local f = string.format

--- Test file to explore _why_ the `fetch` method from the Cursor object
--- isn't working properly, and _how_ to eventually fix it if viable.
--- The main example below follows precisely the instructions given on
--- http://lunarmodules.github.io/luasql/examples.html

local env_a = assert(driver.sqlite3())
local con_a = assert(env_a:connect("./../bbb.db"))
local res_a = con_a:execute("DROP TABLE people;")
res_a = con_a:execute("CREATE TABLE people( name VARCHAR(50), email VARCHAR(50))")

local sample_a = {
  { name = "Jose das Couves", email = "jose@couves.com" },
  { name = "Manoel Joaquim", email = "manoel.joaquim@cafundo.com" },
  { name = "Maria das Dores", email = "maria@dores.com" },
}

for i, p in pairs(sample_a) do
  res_a = assert(con_a:execute(f(
    [[
    INSERT INTO people
    VALUES ('%s', '%s')]],
    p.name,
    p.email
  )))
  print(f("value of res_a for iteration %d: %d", i, res_a))
end

print("- Normal prints by accessing the columns from each iteration of row_a:")
local cur_a = assert(con_a:execute(f("SELECT * FROM people;")))
local row_a = cur_a:fetch({}, "a")
while row_a do
  print(f("----- Name: %s, E-mail: %s", row_a.name, row_a.email))
  -- reusing the table of results
  row_a = cur_a:fetch(row_a, "a")
end

print("- Attempting to dump the row_a 'table':")
pretty.dump(row_a)

cur_a:close() -- already closed because all the result set was consumed
con_a:close()
env_a:close()

--- Test with existing table

local env_b = assert(driver.sqlite3())
local con_b = assert(env_b:connect("./../aaa.db"))
local cur_b = assert(con_b:execute(f("SELECT * FROM test_repo;")))

local row_b = cur_b:fetch({}, "a")

print("- Normal prints by accessing the columns from each iteration of row_b:")
while row_b do
  print(f("----- Name: %s, E-mail: %s, Date: %s", row_b.author_name, row_b.author_email, row_b.date))
  row_b = cur_b:fetch(row_b, "a")
end

print("- Attempting to dump the row_b 'table':")
pretty.dump(row_b)

cur_b:close()
con_b:close()
env_b:close()
