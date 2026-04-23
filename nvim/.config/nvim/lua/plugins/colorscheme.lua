-- ============================================================================
-- lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Tokyonight is the de-facto dark theme for Neovim in 2026 — it ships
-- treesitter + lsp-semantic-token highlights and integrates cleanly with
-- every plugin in this config.  Swap out for "catppuccin" / "kanagawa" /
-- "rose-pine" by changing the `name` in colorscheme() and the table below.
-- ============================================================================
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,       -- colorscheme must load on startup
    priority = 1000,    -- before any other plugin
    opts = {
      style = "night",          -- "storm" | "night" | "moon" | "day"
      transparent = false,
      terminal_colors = true,
      styles = {
        comments   = { italic = true },
        keywords   = { italic = true },
        functions  = {},
        variables  = {},
        sidebars   = "dark",
        floats     = "dark",
      },
      on_highlights = function(hl, c)
        -- tighten up a couple of treesitter groups
        hl.LineNr            = { fg = c.fg_gutter }
        hl.CursorLineNr      = { fg = c.orange, bold = true }
        hl.WinSeparator      = { fg = c.border, bg = "NONE" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Alternate themes (install but don't activate). Switch with :colorscheme X
  { "catppuccin/nvim",       name = "catppuccin", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim",      name = "rose-pine",  lazy = true },
}
