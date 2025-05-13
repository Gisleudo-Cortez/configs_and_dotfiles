-- Bootstrap folke/lazy.nvim -------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Utility: safe require that warns instead of erroring ----------------------
local function srequire(mod)
	local ok, pkg = pcall(require, mod)
	if not ok then vim.notify("Failed loading " .. mod, vim.log.levels.WARN) end
	return ok and pkg or nil
end
_G.srequire = srequire -- make global for reuse

-- Register core options & keys before plugins load --------------------------
require("core.options")
require("core.keymaps")
require("core.path_display")

-- Start lazy ---------------------------------------------------------------
require("lazy").setup({
	{ import = "plugins" },
}, {
	change_detection = { enabled = true, notify = true },
	checker = { enabled = true, concurrency = 20 },
	ui = { border = "rounded" },
})

