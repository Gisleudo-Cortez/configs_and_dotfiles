-- ============================================================================
-- lua/plugins/git.lua
-- ----------------------------------------------------------------------------
-- Inline git signs in the sign column, plus hunk navigation / staging.
-- Full repo operations are handled by `snacks.lazygit` (see snacks.lua).
-- ============================================================================
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      signs_staged = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "▎" },
      },
      signcolumn = true,
      numhl = false,
      current_line_blame = false,   -- toggle with <leader>gt
      current_line_blame_opts = { delay = 500, virt_text_pos = "eol" },
      preview_config = { border = "rounded" },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Hunk navigation
        map("n", "]h", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.nav_hunk("next") end)
          return "<Ignore>"
        end, "Next hunk")
        map("n", "[h", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.nav_hunk("prev") end)
          return "<Ignore>"
        end, "Prev hunk")

        -- Actions
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>",  "Stage hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>",  "Reset hunk")
        map("n", "<leader>ghu", gs.undo_stage_hunk,   "Undo stage hunk")
        map("n", "<leader>ghS", gs.stage_buffer,      "Stage buffer")
        map("n", "<leader>ghR", gs.reset_buffer,      "Reset buffer")
        map("n", "<leader>ghp", gs.preview_hunk,      "Preview hunk")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>ghd", gs.diffthis,          "Diff this")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff this ~")
        map("n", "<leader>gt",  gs.toggle_current_line_blame, "Toggle line blame")

        -- Textobject
        map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<CR>", "Select hunk")
      end,
    },
  },
}
