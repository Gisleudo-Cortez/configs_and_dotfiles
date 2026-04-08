-- lua/core/options.lua
local opt          = vim.opt

-- General UI/UX
opt.termguicolors  = true
opt.number         = true
opt.relativenumber = true
opt.hlsearch       = false
opt.incsearch      = true
opt.ignorecase     = true
opt.smartcase      = true
opt.mouse          = "a"
opt.clipboard      = "unnamedplus"
opt.splitright     = true
opt.splitbelow     = true
opt.signcolumn     = "yes"   -- Always show sign column to prevent text jumping
opt.wrap           = true
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.showmode       = false
opt.pumheight      = 10
opt.updatetime     = 250   -- Slightly faster response for diagnostic/hover
opt.timeoutlen     = 300   -- Faster keymap recognition
opt.undofile       = true

-- Diagnostic UI settings (Modern best practice)
vim.diagnostic.config({
	virtual_text = { prefix = '●' },
	successor = true,
	update_in_insert = false, -- Don't jump while typing
	underline = true,
	severity_sort = true,
	float = { border = "rounded" },
})

vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- Indent scope line color
vim.api.nvim_set_hl(0, "IblScope", { fg = "#a6adc8" })
