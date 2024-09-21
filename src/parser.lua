local Date = require("pl.Date")
local stringx = require("pl.stringx")
local pretty = require("pl.pretty")
local Months = require("utils.constants").months

local M = {}

--- Generates a table containing the branches
---@param file file*? - File with branch names
---@return table<string> - Table containing the branches
function M.branches_to_table(file)
  local branches = {}

  if file ~= nil then
    for line in file:lines() do
      table.insert(branches, line)
    end
  end

  return branches
end

--- Filters the branch table removing remote branches
---@param branches table<string> - Table containing branch names
---@return table<string> remote_branches - Table containing the remote branches
---@return table<string> local_branches - Table containing the local branches
function M.categorize_branches(branches)
  local remote_branches = {}
  local local_branches = {}

  for _, v in ipairs(branches) do
    if string.find(v, "remotes/") then
      table.insert(remote_branches, v)
    else
      table.insert(local_branches, v)
    end
  end

  return remote_branches, local_branches
end

---@class (exact) Commit
---@field author_email string
---@field author_name string
---@field commit string
---@field date string
---@field description string
---@field time number

--- Insert commits in a table where each commit will be serialized with its own fields
---@param path string? - Path of the git repo
---@param branch string? - Name of the branch whose commits will be serialized
---@return table<Commit>
function M.serialize_commits(path, branch)
  path = path or "~/CodeProjects/Studies/Lua/daily-summarizer/"
  branch = branch or "main"
  local processed_commits = {}

  local commit = io.popen(string.format("cd %s && git checkout %s && git log", path, branch))

  if commit ~= nil then
    local single_commit = {}
    for line in commit:lines() do
      if stringx.startswith(line, "commit") then
        local commit_hash = stringx.split(line, " ")[2]
        single_commit.commit = commit_hash
      elseif stringx.startswith(line, "Author") then
        local author = stringx.split(line, ":")[2]
        local author_fields = stringx.split(author, "<")
        local author_name = string.sub(author_fields[1], 2, -2)
        local author_email = string.sub(author_fields[2], 1, -2)
        single_commit.author_name = author_name
        single_commit.author_email = author_email
      elseif stringx.startswith(line, "Date") then
        local date = string.sub(line, 9, -1)
        single_commit.date = date
        local date_parts = stringx.split(date, " ")
        local month, day, year = Months[date_parts[2]], date_parts[3], date_parts[5]
        local clock_time = stringx.split(date_parts[4], ":")
        local time = Date({
          year = year,
          month = month,
          day = day,
          hour = clock_time[1],
          min = clock_time[2],
          sec = clock_time[3],
        }).time
        single_commit.time = time
      elseif #line > 1 then
        single_commit.description = string.sub(line, 5, -1)
        table.insert(processed_commits, single_commit)
        single_commit = {}
      end
    end
  end

  return processed_commits
end

return M
