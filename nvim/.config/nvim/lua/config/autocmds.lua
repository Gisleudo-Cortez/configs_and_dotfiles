-- ============================================================================
-- lua/config/autocmds.lua
-- ============================================================================
local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Highlight on yank ---------------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ timeout = 200 })
  end,
})

-- Restore cursor to last known position --------------------------------------
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc_done then
      return
    end
    vim.b[buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close these filetypes with plain `q` --------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help", "lspinfo", "man", "notify", "qf", "query", "spectre_panel",
    "startuptime", "tsplayground", "neotest-output", "checkhealth",
    "neotest-summary", "neotest-output-panel", "dbout", "gitsigns-blame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
    end)
  end,
})

-- Auto-create parent dirs on :w new-file ------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Resize splits when the Neovim window itself is resized --------------------
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local cur = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. cur)
  end,
})

-- Strip trailing whitespace on save (configurable per-FT below if needed) --
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  pattern = "*",
  callback = function()
    -- skip for these filetypes where whitespace is significant
    local skip = { markdown = true, diff = true, gitcommit = true }
    if skip[vim.bo.filetype] then return end
    local save = vim.fn.winsaveview()
    pcall(vim.cmd, [[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Wrap & spell in text-ish files ---------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Check for file changes on focus -------------------------------------------
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  command = "checktime",
})
