local Date = assert(require("pl.Date"))
local parser = assert(require("src.parser"))
local C = assert(require("utils.constants"))

local M = {}

--- Filters the branch table removing inactive branches
---@param branches table<string>? - List of branch names
---@param project string - Project name as in its url
---@param range { oldest: number, latest: number }? - Range of days to gather commits from, from oldest to newest. Defaults to { oldest: 4, latest: 0 }
---@return table<string> - Table containing the commits
function M.get_commits_in_range(branches, project, range)
  -- Assertions for the params
  assert(type(branches) == "table" or "nil", "get_commits_in_range: Value for 'branches' is not a table or nil")
  assert(type(range) == "table" or "nil", "get_commits_in_range: Value for 'range' is not a table or nil")
  if range ~= nil then
    assert(
      type(range.oldest) == "number",
      "get_commits_in_range: Value for 'range.oldest' is " .. type(range.oldest) .. " and not a number"
    )
    assert(
      type(range.latest) == "number",
      "get_commits_in_range: Value for 'range.latest' is " .. type(range.latest) .. " and not a number"
    )
    assert(
      range.oldest > range.latest,
      "get_commits_in_range: Value for 'range.oldest' has to be larger than 'range.latest'"
    )
  end

  branches = branches or { "main" }
  -- if a range is not given, it'll default to the last 7 days from today
  range = range or { oldest = 7, latest = 0 }
  local commits_in_range = {}

  -- Getting today's date at 00:00:00 so the time of day the script
  -- runs doesn't affect the results
  local today = Date({ hour = 00, min = 00, sec = 00 })

  for i, v in ipairs(branches) do
    -- Gets the commits for the given branch
    local commits = parser.serialize_commits(project, branches[i])

    -- Progress bar implementation
    local done = i / #branches
    if done < 1 and (done * 100) % 10 <= 1 then
      local step = 20
      io.write(
        "\27[2K\27[0GBranch parsing progress > "
          .. string.rep("█", math.ceil(done * step))
          .. string.rep("▒", math.floor(step - (done * step)) - 1)
      )
    end

    -- The part that actuallly filters the commits by the given days range
    if commits ~= nil then
      if today.time - commits[1].time < C.day_length * range.oldest then
        commits_in_range[v] = {}
        for _, commit in ipairs(commits) do
          if
            today.time - commit.time < C.day_length * range.oldest
            and today.time - commit.time > C.day_length * range.latest
          then
            table.insert(commits_in_range[v], commit)
          end
        end
      end
    end
  end

  io.write("\n")

  return commits_in_range
end

return M
