-- Bootstrap Lazy.nvim plugin manager and load core configurations and plugins

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Safe require helper
local function srequire(mod)
	local ok, pkg = pcall(require, mod)
	if not ok then vim.notify("Failed loading " .. mod, vim.log.levels.WARN) end
	return ok and pkg or nil
end

-- ⚠️ Load core settings BEFORE lazy.setup() (NOT as plugins!)
require("core.options")
require("core.keymaps")

-- Setup plugins via lazy.nvim - DON'T import "core" again!
local function setup_lazy()
	require("lazy").setup({
		{ import = "plugins" }, -- Only load plugin specs, NOT config files

	}, {
		change_detection = { enabled = true, notify = false },
		checker = { enabled = true, concurrency = 20 },
		ui = { border = "rounded" },
		performance = {
			rtp = {
				disabled_plugins = { "matchparen", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
			},
		},
	})
end

-- Run setup now (not as a plugin import!)
setup_lazy()
