-- ============================================================================
-- lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Catppuccin Mocha with teal accent — Miku palette alignment.
-- Formerly Tokyonight. Catppuccin is already in the lazy plugin list.
-- ============================================================================
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,       -- colorscheme must load on startup
    priority = 1000,    -- before any other plugin
    opts = {
      flavour = "mocha",       -- darkest variant — matches chassis
      term_colors = true,
      transparent_background = false,
      styles = {
        comments   = { "italic" },
        keywords   = { "italic" },
        functions  = {},
        variables  = {},
      },
      integrations = {
        treesitter = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
        indent_blankline = { enabled = true },
        mini = { enabled = true },
        snacks = { enabled = true },
        which_key = true,
        mason = true,
        notify = true,
        noice = true,
        markdown = true,
        neotree = false,
      },
      highlight_overrides = {
        mocha = function(colors)
          return {
            -- Tighten up: make cursor line number teal instead of peach
            CursorLineNr = { fg = colors.teal, style = { "bold" } },
            -- Win separator in surface colour
            WinSeparator = { fg = colors.surface1 },
            -- Rust unresolved references (false positive suppression)
            ["@lsp.type.unresolvedReference.rust"] = {},
          }
        end,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Alternate themes (install but don't activate). Switch with :colorscheme X
  { "folke/tokyonight.nvim",   lazy = true },
  { "rebelot/kanagawa.nvim",   lazy = true },
  { "rose-pine/neovim",        name = "rose-pine",  lazy = true },
}
