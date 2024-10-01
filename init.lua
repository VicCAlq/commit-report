local Date = require("pl.Date")
local lapp = require("pl.lapp")
local path = require("pl.path")
local stringx = require("pl.stringx")
local pretty = require("pl.pretty")
local parser = require("src.parser")
local filter = require("src.filter")

local args = lapp([[
  Command-line mode for the summarizer.
    -v,--vertical  Vertical layout orientation (defaults to horizontal)
    -l,--latest (default 0)  Most recent date for the fetched commits
    <oldest> (number)  Oldest date for the fetched commits
    <url> (string)  URL for the GIT repo
]])

print(args.vertical, args.latest, args.oldest, args.url)

local url = stringx.split(args.url, "/")
local repo_name = url[#url]
if stringx.endswith(repo_name, ".git") then
  repo_name = stringx.replace(repo_name, ".git", "")
end
pretty.dump(repo_name)

--- Fetches the repository without the blobs
---@param url string - URL for the repo to be analyzed
---@return string? error - Possible error message
local function grabber(url)
  if not path.exists(path.relpath("repos" .. path.sep .. repo_name)) then
    local err, _ = os.execute("cd ./repos && git clone --filter=blob:none " .. url)
    if err then
      return tostring(err)
    end
  end
end

grabber(args.url)

-- local all_branches = io.popen(string.format("cd %s && git branch -a", ), "r")
--
-- local commits = {}
--
-- for k, v in pairs(pl.Date) do
--   print(k, v)
-- end
--
-- if all_branches ~= nil then
--   local remote_branches, local_branches = parser.categorize_branches(parser.branches_to_table(all_branches))
--   filter.remove_inactive_branches(local_branches)
--
--   for branch in all_branches:lines() do
--     if string.find(branch, "remotes/origin") then
--       print("skipped")
--     else
--       local commit_info = {}
--       local commit =
--         io.popen(string.format("cd %s && " .. "git stash && " .. "git checkout %s && " .. "git log -1", path, branch))
--
--       if commit ~= nil then
--         for commit_line in commit:lines() do
--           if string.find(commit_line, "Author") then
--             commit_info.author = commit_line
--           elseif string.find(commit_line, "Date") then
--             commit_info.date = commit_line
--           end
--         end
--       end
--
--       table.insert(commits, commit_info)
--     end
--   end
-- end
--
-- for k, t in pairs(commits) do
--   for _, v in pairs(t) do
--     -- print(v)
--   end
-- end
