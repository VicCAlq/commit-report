local path = "/home/vicmca/CodeProjects/CESAR/Petro/t12/estimador_de_sobressalentes/frontend/"

local branches = io.popen(string.format("cd %s && git branch -a", path))

local commits = {}

if branches ~= nil then
  for line in branches:lines() do
    if line:find("remotes/origin") then
      print("skipped")
    else
      local commit_info = {}
      local commit = io.popen(string.format(
        "cd %s && " ..
        "git stash && " ..
        "git checkout %s && " ..
        "git log -1",
        path, line
      ))

      if commit ~= nil then
        for cline in commit:lines() do
          if cline:find("Author") then
            commit_info.author = cline
          elseif cline.find("Date") then
            commit_info.date = cline
          end
        end
      end

      table.insert(commits, commit_info)
    end
  end
end

for k, t in pairs(commits) do
  for _, v in pairs(t) do
    print(v)
  end
end
