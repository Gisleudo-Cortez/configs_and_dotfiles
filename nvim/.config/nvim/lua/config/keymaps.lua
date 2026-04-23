-- ============================================================================
-- lua/config/keymaps.lua — Global keymaps (non-plugin)
-- ----------------------------------------------------------------------------
-- Convention:  <leader>  = <Space>
--              <leader>w = save (as requested)
--              <leader>q = quit
--              <leader>f* = find
--              <leader>c* = code
--              <leader>g* = git
--              <leader>d* = debug
--              <leader>x* = diagnostics / trouble
--              <leader>u* = toggle UI
--              <leader>b* = buffers
--              <leader>s* = search
-- Plugin-specific keymaps live next to their plugin spec (lua/plugins/*.lua).
-- ============================================================================

local map = function(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false  -- silent by default
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- ── File operations ────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>w<CR>",  { desc = "Save" })
map("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all" })
map("n", "<leader>wq","<cmd>wq<CR>", { desc = "Save and quit" })        -- ported from old config
map("n", "<leader>q", "<cmd>confirm q<CR>",  { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qa<CR>", { desc = "Quit all" })

-- Save in insert mode without leaving it
map("i", "<C-s>", "<Esc><cmd>w<CR>a", { desc = "Save (insert)" })
map("n", "<C-s>", "<cmd>w<CR>",        { desc = "Save" })

-- ── Window management ──────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window"  })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

map("n", "<C-Up>",    "<cmd>resize +2<CR>",          { desc = "Increase height" })
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          { desc = "Decrease height" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", { desc = "Decrease width"  })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width"  })

map("n", "<leader>-", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>|", "<C-w>v", { desc = "Split vertical"   })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window"  })

-- ── Buffers ────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "[b",    "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "]b",    "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bd<CR>",       { desc = "Delete buffer" })
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Delete other buffers" })
map("n", "<leader>`", "<cmd>e #<CR>", { desc = "Switch to last buffer" })

-- ── Editing niceties ───────────────────────────────────────────────────────
-- Keep cursor centred on big jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- Move selected lines (Visual mode)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up"   })

-- Move single line up/down (Normal mode)
-- Ported from old config's <leader>j/<leader>k — relocated to <A-j>/<A-k>
-- because <leader>j* is the Jupyter/molten prefix in this config.
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up"   })
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up"   })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep selection when indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Paste over selection without clobbering register
map("x", "p", [["_dP]], { desc = "Paste without yank" })

-- Delete without yank
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete (no yank)" })

-- Clear search highlight
map({ "i", "n" }, "<Esc>", "<cmd>noh<CR><Esc>", { desc = "Clear search highlight" })

-- Better escape from terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ── Diagnostics ────────────────────────────────────────────────────────────
map("n", "]d", function() vim.diagnostic.jump({ count = 1,  float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]e", function() vim.diagnostic.jump({ count = 1,  severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "Next error" })
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "Prev error" })
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostic" })
map("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })

-- ── UI toggles (mnemonic: u = UI) ─────────────────────────────────────────
map("n", "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end,
  { desc = "Toggle line wrap" })
map("n", "<leader>us", function() vim.wo.spell = not vim.wo.spell end,
  { desc = "Toggle spell" })
map("n", "<leader>ul", function() vim.wo.number = not vim.wo.number end,
  { desc = "Toggle line numbers" })
map("n", "<leader>uL", function() vim.wo.relativenumber = not vim.wo.relativenumber end,
  { desc = "Toggle relative numbers" })
map("n", "<leader>ud", function()
  local new_config = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = new_config, virtual_lines = false })
  vim.notify("Diagnostics " .. (new_config and "enabled" or "disabled"))
end, { desc = "Toggle diagnostics" })
