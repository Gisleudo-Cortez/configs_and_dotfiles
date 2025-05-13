return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      lazy = false,
      opts = {
        flavour = "mocha",
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          telescope   = true,
          nvimtree    = true,
          mason       = true,
        },
      },
      config = function(_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme("catppuccin-mocha")
      end,
    },
  }