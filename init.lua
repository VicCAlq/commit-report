local Date = require("pl.Date")
local lapp = require("pl.lapp")
local path = require("pl.path")
local parser = require("src.parser")
local filter = require("src.filter")

local args = lapp([[
  Test for lapp
    -l, --layout (default "v")  Layout orientation ("v" for Vertical, "h" for Horizontal)
    -d, --days (number, number)  Range of days
    <url> (string)  URL for the GIT repo
]])

print(args.layout, args.days, args.url)
