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

return M
