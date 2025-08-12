-- Bootstrap Lazy.nvim plugin manager and load core configurations and plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Safe require: does not throw error if module is missing
local function srequire(mod)
	local ok, pkg = pcall(require, mod)
	if not ok then vim.notify("Failed loading " .. mod, vim.log.levels.WARN) end
	return ok and pkg or nil
end
_G.srequire = srequire -- make global for reuse in configs

-- Load core settings and keymaps before plugins
require("core.options")
require("core.keymaps")
-- (Optional module core.path_display was removed as its functionality was redundant)

-- Setup plugins via lazy.nvim
require("lazy").setup({
	{ import = "plugins" }
}, {
	change_detection = { enabled = true, notify = true },
	checker = { enabled = true, concurrency = 20 },
	ui = { border = "rounded" },
	performance = {
		rtp = {
			disabled_plugins = { "matchparen", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
		},
	},
})
