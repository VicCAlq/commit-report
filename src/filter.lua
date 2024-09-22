local Date = require("pl.Date")
local pretty = require("pl.pretty")
local parser = require("src.parser")
local C = require("utils.constants")

local M = {}

--- Filters the branch table removing inactive branches
---@param branches table<string>? - List of branch names
---@param range { oldest: number, latest: number }? - Range of days to gather commits from, from oldest to newest. Defaults to { oldest: 4, latest: 0 }
---@return table<string> - Table containing the commits
function M.get_commits_in_range(branches, range)
  -- Assertions for the params
  assert(type(branches) == "table", "The value given for 'branches' is not a table")
  assert(type(range) == "table", "The value given for 'range' is not a table")
  assert(type(range.oldest) == "number", "The value given for 'range.oldest' is not a number")
  assert(type(range.latest) == "number", "The value given for 'range.latest' is not a number")
  assert(range.oldest > range.latest, "The value for 'range.oldest' has to be larger than 'range.latest'")

  branches = branches or { "main", "feat/filters" }
  range = range or { oldest = 4, latest = 0 }
  local commits_in_range = {}

  for i, v in ipairs(branches) do
    local commits = parser.serialize_commits(C.test_path, branches[i])
    commits_in_range[v] = {}

    if commits ~= nil then
      for _, commit in ipairs(commits) do
        -- Getting today's date at 00:00:00 so the time of day the script
        -- runs doesn't affect the results
        local today = Date({ hour = 00, min = 00, sec = 00 })
        if
          today.time - commit.time < C.day_length * range.oldest
          and today.time - commit.time > C.day_length * range.latest
        then
          table.insert(commits_in_range[v], commit)
        end
      end
    end
  end

  -- pretty.dump(commits_in_range)
  return commits_in_range
end

M.get_commits_in_range(nil, nil)

return M
