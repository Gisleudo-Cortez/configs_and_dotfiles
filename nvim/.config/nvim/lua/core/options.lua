local opt            = vim.opt

opt.termguicolors    = true -- 24-bit colour
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
opt.updatetime       = 300
opt.timeoutlen       = 500
opt.undofile         = true

vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- Indent scope line color (adjust for Catppuccin-Mocha)
vim.api.nvim_set_hl(0, "IblScope", { fg = "#a6adc8" }) -- Matches Mocha "overlay0"
