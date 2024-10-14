local path = assert(require("pl.path"))
local stringx = assert(require("pl.stringx"))
local f = string.format

local M = {}

--- Fetches the repository without the blobs and stores it inside the /repos folder
---@param url string - URL for the repo to be analyzed
---@return string error_or_name - Possible error message or repository name
function M.clone(url)
  assert(type(url) == "string", "clone: <url> must be a valid string")

  local repo_url = stringx.split(url, "/")
  -- Name must follow the template "owner.repository/"
  local repo_name = repo_url[f("%s.%s", repo_url[#repo_url - 1], repo_url[#repo_url])] or ""
  if stringx.endswith(repo_name, ".git") then
    repo_name = stringx.replace(repo_name, ".git", "")
  end

  if not path.exists(path.relpath("repos" .. path.sep .. repo_name)) then
    -- Cloning without any blobs, but without the --bare option to keep the branches
    local err, _ = os.execute("cd ./repos && git clone --filter=blob:none " .. url)
    if err then
      error("Could not clone the repository from the url " .. url)
    end
  else
    local err, _ =
      os.execute("cd ./repos/" .. repo_name .. " && echo -n 'Repository status: ' && git fetch --all && git pull")
    if err ~= 0 then
      error("Could not fetch updates for the repository " .. repo_name)
    end
  end

  return repo_name
end

return M
