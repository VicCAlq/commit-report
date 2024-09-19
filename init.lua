local pl = require("pl.import_into")()
local path = "/home/vicmca/CodeProjects/CESAR/Petro/t12/estimador_de_sobressalentes/frontend/"
local parser = require("src.parser")
local filter = require("src.filter")

local all_branches = io.popen(string.format("cd %s && git branch -a", path), "r")

local commits = {}

for k, v in pairs(pl.Date) do
	print(k, v)
end

if all_branches ~= nil then
	local remote_branches, local_branches = parser.categorize_branches(parser.branches_to_table(all_branches))
	filter.remove_inactive_branches(local_branches)

	for branch in all_branches:lines() do
		if string.find(branch, "remotes/origin") then
			print("skipped")
		else
			local commit_info = {}
			local commit = io.popen(
				string.format("cd %s && " .. "git stash && " .. "git checkout %s && " .. "git log -1", path, branch)
			)

			if commit ~= nil then
				for commit_line in commit:lines() do
					if string.find(commit_line, "Author") then
						commit_info.author = commit_line
					elseif string.find(commit_line, "Date") then
						commit_info.date = commit_line
					end
				end
			end

			table.insert(commits, commit_info)
		end
	end
end

for k, t in pairs(commits) do
	for _, v in pairs(t) do
		-- print(v)
	end
end
