-- ============================================================================
-- init.lua — Neovim entry point
-- ----------------------------------------------------------------------------
-- Load order:
--   1. Set leader *before* lazy.nvim loads (mappings depend on it)
--   2. Core options / keymaps / autocmds
--   3. Bootstrap lazy.nvim and pull in all plugin specs from lua/plugins/
-- ============================================================================

-- Must be set BEFORE lazy.nvim is required.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Performance: skip some built-in plugins we don't need.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- Core config modules.
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugin manager — auto-imports every file under lua/plugins/.
require("config.lazy")
