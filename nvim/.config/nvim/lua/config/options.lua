-- ============================================================================
-- lua/config/options.lua — Editor options
-- ============================================================================
local opt = vim.opt
-- Python host: point nvim at the dedicated venv so molten / pynvim work.
local nvim_python = vim.fn.expand("~/.virtualenvs/neovim/bin/python")
if vim.fn.filereadable(nvim_python) == 1 then
  vim.g.python3_host_prog = nvim_python
end
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
-- UI ------------------------------------------------------------------------
opt.number = true -- absolute line number on current line
opt.relativenumber = true -- relative numbers on all other lines
opt.signcolumn = "yes" -- always show sign column (prevents layout jumps)
opt.cursorline = true -- highlight current line
opt.termguicolors = true -- 24-bit colour
opt.showmode = false -- mode is in lualine, don't echo at bottom
opt.laststatus = 3 -- single global statusline
opt.cmdheight = 1
opt.pumheight = 10 -- cap popup menu height
opt.winborder = "rounded" -- rounded borders for all floats (Nvim 0.11+)
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen" -- stable viewport across splits
opt.scrolloff = 8 -- min lines above/below cursor
opt.sidescrolloff = 8
opt.wrap = false -- no soft-wrap by default (toggle w/ <leader>uw)
opt.linebreak = true -- if wrap is on, break at word boundaries
opt.list = true -- show invisible chars
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
-- fillchars: every value must be exactly 1 character on Nvim 0.12+.
-- Using plain ASCII so this config works even without a Nerd Font.
opt.fillchars = { eob = " ", fold = " ", foldopen = "v", foldclose = ">" }

-- Behaviour -----------------------------------------------------------------
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- share clipboard with OS
opt.undofile = true -- persist undo across sessions
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.updatetime = 200 -- faster CursorHold (LSP hover hint etc.)
opt.timeoutlen = 400 -- snappier which-key
opt.confirm = true -- prompt on unsaved quit instead of failing
opt.virtualedit = "block" -- visual block can go past EOL
opt.completeopt = { "menu", "menuone", "noselect" }
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

-- Indentation ---------------------------------------------------------------
opt.expandtab = true -- spaces, not tabs
opt.shiftwidth = 4 -- default; treesitter / per-FT ftplugins override
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- Search --------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true -- case-sensitive iff query contains uppercase
opt.inccommand = "split" -- live preview for :s

-- Folding (powered by treesitter, see plugins/treesitter.lua) ---------------
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Session -------------------------------------------------------------------
opt.sessionoptions =
  { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Formatting ----------------------------------------------------------------
opt.formatoptions = "jcroqlnt" -- j: remove comment leader on J, r: auto-continue comment, etc.

-- Spell (off by default; flip per-FT, see autocmds) -------------------------
opt.spelllang = { "en" }

-- Diagnostics (Nvim 0.11+ API) ---------------------------------------------
vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
  float = { border = "rounded", source = "if_many" },
})
