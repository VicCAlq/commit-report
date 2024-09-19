local pl = require("pl.import_into")()

local M = {}

--- 1. Extract commit date string
--- 2. Trim until month short name
--- 3. Fraction the string by the " " and ":"
--- 4. Order is Month, Day, Hour, Minute, Second, Year, Time Zone
---    Like so: "Date:   Tue Sep 17 18:57:05 2024 -0300"
--- 5. Store in a table containing the keys "year", "month", "day", "hour", "min", "sec"
--- 6. Build a date object from this table
--- 7. Use the "time" key to compare the current time from today at 00:00 to the commit time
--- 8. Use the range as multipliers to the DayLength value to compare if the commit date
---    is within the acceptable range

local DayLength = 86400

local months = {
  Jan = 1,
  Feb = 2,
  Mar = 3,
  Apr = 4,
  May = 5,
  Jun = 6,
  Jul = 7,
  Aug = 8,
  Sep = 9,
  Oct = 10,
  Nov = 11,
  Dec = 12,
}

local date_1 = pl.Date({ year = 2020, month = 1, day = 1, hour = 00, min = 00, sec = 00 })
local date_2 = pl.Date({ year = 2020, month = 1, day = 2, hour = 00, min = 00, sec = 00 })
--[[
  time    1592005530
  hour    20
  min     45
  wday    6
  day     12
  month   6
  year    2020
  sec     30
  yday    164
  isdst   false
]]

for k, v in pairs(date_1) do
  if type(v) == "table" then
    for key, val in pairs(v) do
      print(key, val)
    end
  else
    print(k, v)
  end
end

for k, v in pairs(date_2) do
  if type(v) == "table" then
    for key, val in pairs(v) do
      print(key, val)
    end
  else
    print(k, v)
  end
end

--- Filters the branch table removing inactive branches
---@param branches table<string> - Table containing branch names
---@param range { oldest: number, latest: number }? - Range of days to gather commits from, from oldest to newest. Defaults to { oldest: 2, latest: 0 }
---@return table<string> - Table containing the branches
function M.remove_inactive_branches(branches, range_days)
  local range = range_days or { oldest = 2, latest = 0 }
  local filtered_branches = {}

  --[[
    Commit format
    commit 8839f79777e30b237e61c0cec7fbec1fe601592d (HEAD -> feat/filters, docs/specs)
    Author: Victor Cavalcanti <victor.mca.dev@gmail.com>
    Date:   Tue Sep 17 18:57:05 2024 -0300
  
    p.docs: Basic project specifications written
  ]]

  for _, v in ipairs(branches) do
    local commit = {
      hash = "",
      author = "",
      contact = "",
      date = "",
      content = "",
    }
  end

  return filtered_branches
end

return M
