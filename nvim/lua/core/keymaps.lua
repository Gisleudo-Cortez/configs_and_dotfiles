local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Save / Quit
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")
map("n", "<leader>wq", ":wq<CR>")
map("n", "<leader>Q", ":qa!<CR>")

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("n", "<leader>j", ":m .+1<CR>==")
map("n", "<leader>k", ":m .-2<CR>==")

-- Terminal toggle
local term_win
function _G.ToggleTerminal()
  if not term_win or not vim.api.nvim_win_is_valid(term_win) then
    vim.cmd("15split | terminal")
    term_win = vim.api.nvim_get_current_win()
    vim.cmd("startinsert")
  elseif vim.api.nvim_get_current_win() == term_win then
    vim.cmd("q")
  else
    vim.api.nvim_set_current_win(term_win)
  end
end
map("n", "<leader>tt", "<cmd>lua ToggleTerminal()<CR>", { desc = "Terminal" })