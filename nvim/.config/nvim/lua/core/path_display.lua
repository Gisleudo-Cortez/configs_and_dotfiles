-- lua/core/path_display.lua
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	callback = function()
		local path = vim.api.nvim_buf_get_name(0)
		local parts = {}
		for part in string.gmatch(path, "[^/]+") do
			table.insert(parts, part)
		end
		local count = #parts
		local display = table.concat({
			parts[count - 2] or "",
			parts[count - 1] or "",
			parts[count] or "",
		}, "/")
		vim.notify(display, vim.log.levels.INFO, { title = "Opened File" })
	end,
})
