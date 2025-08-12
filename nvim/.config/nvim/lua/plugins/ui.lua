-- UI enhancements (statusline, bufferline, dashboard, notifications, icons)
return {
  -- Icons (for filetypes, etc., used by many plugins)
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Statusline (lualine)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local components = require("core.components")
      return {
        options = {
          theme = "catppuccin",
          component_separators = "|",
          section_separators = "",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = { components.truncated_path },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "nvim-tree", "quickfix", "mason" },
      }
    end,
  },

  -- Bufferline (show open buffers in the tabline)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  -- Dashboard (start screen)
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    config = function()
      require("dashboard").setup({
        theme = "hyper",
        config = {
          week_header = { enable = true },
          shortcut = {
            { desc = " Find File",   group = "@keyword", action = "Telescope find_files", key = "f" },
            { desc = "󰱼 Live Grep",    group = "@keyword", action = "Telescope live_grep",  key = "g" },
            { desc = " File Explorer", group = "@keyword", action = "NvimTreeToggle",     key = "e" },
            { desc = " Plugins",      group = "Number",    action = "Lazy",                key = "l" },
          },
        },
      })
    end,
  },

  -- Notifications (nvim-notify)
  {
    "rcarriga/nvim-notify",
    lazy = false, -- load immediately to override vim.notify
    config = function() vim.notify = require("notify") end,
  },
}
