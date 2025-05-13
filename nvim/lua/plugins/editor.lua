return {
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", opts = {
        ensure_installed = {
          "bash","c","css","html","javascript","json","lua","python","rust","go",
          "typescript","vim","yaml","sql"
        },
        highlight = { enable = true },
        indent    = { enable = true },
      }
    },
    { "lewis6991/gitsigns.nvim", event = { "BufReadPre","BufNewFile" }, opts = {} },
    { "windwp/nvim-autopairs",  event = "InsertEnter", opts = {} },
  }