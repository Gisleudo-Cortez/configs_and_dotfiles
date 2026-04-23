-- ============================================================================
-- lua/config/lazy.lua — lazy.nvim bootstrap
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Import every Lua file in lua/plugins/ as a plugin spec source.
    { import = "plugins" },
  },
  defaults = {
    lazy = false,   -- default: plugins load eagerly; opt-in lazy via `event=`, `keys=`, etc.
    version = false, -- always use latest git — set to "*" to follow latest stable tags
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false },  -- auto-check for updates (no popup)
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
        "netrwPlugin",  -- we use snacks.explorer instead
      },
    },
  },
})

-- Open lazy UI
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Lazy (plugin manager)" })
