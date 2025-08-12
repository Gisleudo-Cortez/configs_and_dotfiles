local M = {}

local function last_n(parts, n)
	local res, start = {}, math.max(1, #parts - n + 1)
	for i = start, #parts do table.insert(res, parts[i]) end
	return res
end

function M.truncated_path()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then return "[No Name]" end
	path = vim.fs.normalize(path)
	local parts = {}
	for part in string.gmatch(path, "[^/\\]+") do
		table.insert(parts, part)
	end
	return table.concat(last_n(parts, 3), "/")
end

return M
