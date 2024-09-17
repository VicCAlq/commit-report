local path = "/home/vicmca/CodeProjects/CESAR/Petro/t12/estimador_de_sobressalentes/frontend/"

local all_branches = io.popen(string.format("cd %s && git branch -a", path), "r")

local commits = {}

--- Generates a table containing the branches
---@param file file*? - File with branch names
---@return table<string> - Table containing the branches
local function branches_to_table(file)
	local branches = {}

	if file ~= nil then
		for line in file:lines() do
			table.insert(line)
		end
	end

	return branches
end

local branch_table = branches_to_table(all_branches)

--- Filters the branch table removing remote branches
---@param branches table<string> - Table containing branch names
---@return table<string> - Table containing the branches
local function remove_remote_branches(branches)
	local filtered_branches = {}

	for _, v in branches do
		if not string.find(v, "remotes/") then
			table.insert(filtered_branches, v)
		end
	end

	return filtered_branches
end

--- Filters the branch table removing inactive branches
---@param branches table<string> - Table containing branch names
---@param inactive_days number? - Quantity of days to be considered inactive. Defaults to 2
---@return table<string> - Table containing the branches
local function remove_inactive_branches(branches, inactive_days)
	local days = inactive_days or 2
	local filtered_branches = {}

	return filtered_branches
end

if all_branches ~= nil then
	local parsed_branches = remove_remote_branches(branches_to_table(all_branches))

	for line in all_branches:lines() do
		if string.find(line, "remotes/origin") then
			print("skipped")
		else
			local commit_info = {}
			local commit = io.popen(
				string.format("cd %s && " .. "git stash && " .. "git checkout %s && " .. "git log -1", path, line)
			)

			if commit ~= nil then
				for cline in commit:lines() do
					if string.find(cline, "Author") then
						commit_info.author = cline
					elseif string.find(cline, "Date") then
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
