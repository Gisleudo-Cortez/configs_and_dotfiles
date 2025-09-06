return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "bash", "c", "css", "html", "javascript", "json", "lua", "python",
        "rust", "go", "typescript", "vim", "yaml", "sql", "markdown", "java",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {}, -- use default settings
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}, -- use default settings
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})
      wk.add({
        { "<leader>b", group = "Buffer", remap = false },
        { "<leader>f", group = "Find", remap = false },
        { "<leader>t", group = "Terminal", remap = false },
        { "<leader>w", desc = "Save file" },
        { "<leader>wq", desc = "Save & quit" },
        { "<leader>bd", desc = "Delete buffer" },
        { "<leader>ff", desc = "Find Files" },
        { "<leader>fg", desc = "Live Grep" },
        { "<leader>fb", desc = "Find Buffers" },
        { "<leader>tt", desc = "Toggle terminal" },
      }, { mode = "n" })
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    },
    opts = {
      size = 15,
      open_mapping = nil,
      shade_terminals = true,
      direction = "horizontal",
    },
  },

  -- ⬇️ NEW: Indent scope highlighting
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = {
        char = "│",
      },
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
      },
      exclude = {
        filetypes = {
          "help",
          "dashboard",
          "lazy",
          "mason",
          "nvimtree",
          "terminal",
        },
      },
    },
  },
}
