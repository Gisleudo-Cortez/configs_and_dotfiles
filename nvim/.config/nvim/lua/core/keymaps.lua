-- lua/core/keymaps.lua

local map  = vim.keymap.set
local opts = { noremap = true, silent = true }

if not vim.g.mapleader then
	vim.g.mapleader = " "
end

-- FIX: Removed the <Space> -> noice.cmd("leader") mapping.
-- That API does not exist, so pressing Space in normal mode errored before
-- which-key could intercept it, silently breaking every leader keymap.
-- which-key.nvim shows hints automatically after the leader timeout — no
-- manual binding is needed here.

-- Window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true, desc = "Delete buffer" })

-- Save and quit
map("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { noremap = true, silent = true, desc = "Quit" })
map("n", "<leader>wq", ":wq<CR>", { noremap = true, silent = true, desc = "Save and quit" })
map("n", "<leader>Q", ":qa!<CR>", { noremap = true, silent = true, desc = "Quit without saving" })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)
map("n", "<leader>j", ":m .+1<CR>==", opts)
map("n", "<leader>k", ":m .-2<CR>==", opts)
