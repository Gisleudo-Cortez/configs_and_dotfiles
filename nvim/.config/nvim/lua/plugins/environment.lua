-- ============================================================================
-- lua/plugins/environment.lua
-- ----------------------------------------------------------------------------
-- Arch + Hyprland + Kitty + Fish integration.  Two sections:
--   1. Filetype detection (pure vim — no plugins needed)
--   2. kitty-scrollback.nvim (optional) for editing Kitty's scrollback in nvim
-- ============================================================================

-- ─── 1. Filetype detection ────────────────────────────────────────────────
-- Lua-based vim.filetype.add runs before any plugin; safe to do unconditionally.
vim.filetype.add({
  filename = {
    [".hyprlandrc"]      = "hyprlang",
    ["hyprland.conf"]    = "hyprlang",
    ["hyprpaper.conf"]   = "hyprlang",
    ["hypridle.conf"]    = "hyprlang",
    ["hyprlock.conf"]    = "hyprlang",
    ["kitty.conf"]       = "kitty",
    ["config.kdl"]       = "kdl",
    ["PKGBUILD"]         = "PKGBUILD",             -- built-in Arch support
    [".env"]             = "sh",                    -- handy for dotenv-at-root projects
    [".envrc"]           = "sh",                    -- direnv
  },
  pattern = {
    [".*/hypr/.*%.conf"]           = "hyprlang",
    [".*/kitty/.*%.conf"]          = "kitty",
    [".*/fish/config%.fish"]       = "fish",
    [".*/fish/functions/.*%.fish"] = "fish",
    [".*/fish/conf%.d/.*%.fish"]   = "fish",
    [".*/waybar/config.*"]         = "jsonc",       -- waybar on hyprland
    [".*/rofi/.*%.rasi"]           = "rasi",
    [".*/sway/config"]             = "swayconfig",
  },
})

-- PKGBUILD inherits bash-ish settings; wire up some extras.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_arch_ft", { clear = true }),
  pattern = { "PKGBUILD", "install" },
  callback = function() vim.bo.filetype = "sh" end,
})

-- ─── 2. Plugin specs ──────────────────────────────────────────────────────
return {
  -- ─── kitty-scrollback.nvim ──────────────────────────────────────────────
  -- Requires Kitty config + a kitten mapping.  See README for the Kitty
  -- side (takes ~2 minutes to set up).  Harmless if you skip it.
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = function() return vim.env.TERM == "xterm-kitty" end,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth", "KittyScrollbackGenerateCommandLineEditing" },
    event = { "User KittyScrollbackLaunch" },
    version = "*",
    config = function() require("kitty-scrollback").setup() end,
  },

  -- ─── hyprlang syntax fallback (if treesitter parser unavailable) ────────
  -- The TS parser for hyprlang handles highlighting; this vim plugin is a
  -- cheap fallback for filetype inference + legacy syntax.
  {
    "luckasRanarison/tree-sitter-hypr",
    ft = "hyprlang",
    lazy = true,
  },
}
