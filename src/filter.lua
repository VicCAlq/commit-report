local Date = require("pl.Date")
local stringx = require("pl.stringx")
local pretty = require("pl.pretty")
local parser = require("src.parser")
local constants = require("utils.constants")

local M = {}

--- 1. Extract commit date string
--- 2. Trim until month short name
--- 3. Fraction the string by the " " and ":":while true do
--- 4. Order is Month, Day, Hour, Minute, Second, Year, Time Zone
---    Like so: "Date:   Tue Sep 17 18:57:05 2024 -0300"
--- 5. Store in a table containing the keys "year", "month", "day", "hour", "min", "sec"
--- 6. Build a date object from this table
--- 7. Use the "time" key to compare the current time from today at 00:00 to the commit time
--- 8. Use the range as multipliers to the DayLength value to compare if the commit date
---    is within the acceptable range

--[[
  time    1592005530
  table     {
    hour    20
    min     45
    wday    6
    day     12
    month   6
    year    2020
    sec     30
    yday    164
    isdst   false
  }
]]

--- Gets commits from the given branch
---@param branches table<string> - List of branch names
---@param range { oldest: number, latest: number }? - Range of days to gather commits from, from oldest to newest. Defaults to { oldest: 2, latest: 0 }
---@return table<table<string>> - Table containing the commits for each branch
function M.get_commits_from_branches(branches, range)
  local filtered_commits = {}

  for _, v in ipairs(branches) do
  end
end

--- Filters the branch table removing inactive branches
---@param branches table<string> - List of branch names
---@param range { oldest: number, latest: number }? - Range of days to gather commits from, from oldest to newest. Defaults to { oldest: 2, latest: 0 }
---@return table<string> - Table containing the commits
function M.get_commits_in_range(branches, range)
  branches = branches or { "main", "feat/filters" }
  range = range or { oldest = 44, latest = 0 }
  local commits_in_range = {}

  for i, v in ipairs(branches) do
    local commits = parser.serialize_commits(constants.test_path, branches[i])

    if commits ~= nil then
      for _, c in ipairs(commits) do
        local today = Date({ hour = 00, min = 00, sec = 00 })
        if today.time - c.time < constants.day_length * range.oldest then
          commits_in_range[v] = c
        end
      end
    end
  end

  -- local commits = parser.serialize_commits(constants.test_path, branches[1])
  --
  -- if commits ~= nil then
  --   for _, c in ipairs(commits) do
  --     local today = Date({ hour = 00, min = 00, sec = 00 })
  --     if today.time - c.time < constants.day_length * range.oldest then
  --       table.insert(commits_in_range, c)
  --     end
  --   end
  -- end
  --
  pretty.dump(commits_in_range)
  return commits_in_range
end

M.get_commits_in_range(nil, nil)

return M
