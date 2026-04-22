-- lua/core/options.lua

local opt            = vim.opt

vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- General UI/UX
opt.termguicolors    = true
opt.number           = true
opt.relativenumber   = true
opt.hlsearch         = false
opt.incsearch        = true
opt.ignorecase       = true
opt.smartcase        = true
opt.mouse            = "a"
opt.clipboard        = "unnamedplus"
opt.splitright       = true
opt.splitbelow       = true
opt.signcolumn       = "yes"
opt.wrap             = true
opt.scrolloff        = 8
opt.sidescrolloff    = 8
opt.showmode         = false
opt.pumheight        = 10
opt.updatetime       = 250
opt.timeoutlen       = 300
opt.undofile         = true

-- Diagnostic UI settings
vim.diagnostic.config({
	virtual_text     = { prefix = "●" },
	-- FIX: "successor" is not a valid key; the correct key is "signs".
	-- Without this, gutter diagnostic signs (E/W/I/H) were silently disabled.
	signs            = true,
	update_in_insert = false,
	underline        = true,
	severity_sort    = true,
	float            = { border = "rounded" },
})

-- Indent scope line color
vim.api.nvim_set_hl(0, "IblScope", { fg = "#a6adc8" })
