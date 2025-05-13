return {
    {
      "nvim-tree/nvim-tree.lua",
      cmd = { "NvimTreeToggle", "NvimTreeFocus" },
      keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "File Explorer" },
      },
      opts = {
        view = { width = 35 },
        renderer = {
          highlight_git = true,
          icons = { show = { folder_arrow = false } },
        },
        diagnostics = { enable = true },
        git = { enable = true },
      },
    },
  }