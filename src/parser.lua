local Date = require("pl.Date")
local path = require("pl.path")
local stringx = require("pl.stringx")
local pretty = require("pl.pretty")
local Months = require("utils.constants").months

local M = {}

--- Generates a table containing the branches
---@param project string - Project name as in its url
---@return table<string> - Table containing the branches
function M.branches_to_table(project)
  local raw_branches =
    io.popen(string.format("cd %s && git branch -a", path.relpath("repos" .. path.sep .. project)), "r")
  local branches = {}

  if raw_branches ~= nil then
    for line in raw_branches:lines() do
      table.insert(branches, stringx.lstrip(line, " *"))
    end
  end

  return branches
end

--- Filters the branch table removing remote branches
---@param branches table<string> - Table containing branch names
---@return table<string> remote_branches - Table containing the remote branches
---@return table<string> local_branches - Table containing the local branches
function M.categorize_branches(branches)
  assert(type(branches) == "table", "categorize_branches: The value given for 'branches' is not a table")

  local remote_branches = {}
  local local_branches = {}

  for _, v in ipairs(branches) do
    if string.find(v, "remotes/") then
      if not string.find(v, "HEAD") then
        table.insert(remote_branches, v)
      end
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
---@param project string - Project name as in its url
---@param branch string? - Name of the branch whose commits will be serialized
---@return table<Commit>
function M.serialize_commits(project, branch)
  assert(type(project) == "string", "serialize_commits: The value given for 'project' is not a string")
  assert(type(branch) == "string", "serialize_commits: The value given for 'branch' is not a string")

  -- Defaults to branch "main"
  if branch == nil then
    branch = "main"
  elseif stringx.startswith(branch, "remotes/origin/") then
    branch = string.sub(branch, 16, #branch)
  end

  local project_path = path.relpath("repos" .. path.sep .. project)
  local processed_commits = {}

  -- Gets the logs
  local commit = io.popen(string.format("cd %s && git switch -fq --progress %s && git log", project_path, branch))

  -- Parsing operations
  if commit ~= nil then
    local single_commit = {}
    for line in commit:lines() do
      -- Gets the commit hash
      if stringx.startswith(line, "commit") then
        -- If there's a commit already previously parsed it'll be added to the commit list
        if
          single_commit.description ~= nil
          and single_commit.date ~= nil
          and single_commit.author_name ~= nil
          and single_commit.author_email ~= nil
        then
          table.insert(processed_commits, single_commit)
          single_commit = {}
        end
        single_commit.commit_hash = stringx.split(line, " ")[2]
      -- Gets author's name and email
      elseif stringx.startswith(line, "Author") then
        local author = stringx.split(line, ":")[2]
        local author_fields = stringx.split(author, "<")
        single_commit.author_name = string.sub(author_fields[1], 2, -2)
        single_commit.author_email = string.sub(author_fields[2], 1, -2)
      -- Gets the Date object and unix time
      elseif stringx.startswith(line, "Date") then
        local date_parts = stringx.split(string.sub(line, 9, -1), " ")
        local year, month, day = date_parts[5], Months[date_parts[2]], date_parts[3]
        local clock_time = stringx.split(date_parts[4], ":")

        local formatted_date = {}

        for _, v in ipairs({ year, month, day }) do
          if tonumber(v) < 10 then
            v = "0" .. v
          end
          table.insert(formatted_date, v)
        end

        single_commit.date = string.format(
          "%s-%s-%s %s:%s:%s.000",
          formatted_date[1],
          formatted_date[2],
          formatted_date[3],
          clock_time[1],
          clock_time[2],
          clock_time[3]
        )

        single_commit.unix_time = Date({
          year = year,
          month = month,
          day = day,
          hour = clock_time[1],
          min = clock_time[2],
          sec = clock_time[3],
        }).time
      -- Gets the commit message
      elseif #line > 1 then
        if single_commit.description == nil then
          single_commit.description = stringx.lstrip(line)
        else
          single_commit.description = single_commit.description .. "\n" .. line
        end
      end
      single_commit.branch = branch
    end
  end

  return processed_commits
end

return M
