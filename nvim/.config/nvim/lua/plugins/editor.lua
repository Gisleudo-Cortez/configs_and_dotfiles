-- ============================================================================
-- lua/plugins/editor.lua
-- ----------------------------------------------------------------------------
-- Editing-layer plugins that aren't strictly LSP / completion / UI.
-- ============================================================================
return {
  -- ── Autopairs ────────────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,                        -- treesitter-aware
      ts_config = { lua = { "string" }, javascript = { "template_string" } },
      fast_wrap = {
        map = "<M-e>",                        -- Alt-e to surround next thing
        chars = { "{", "[", "(", '"', "'" },
        pattern = [=[[%'%"%)%>%]%)%}%,]]=],
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
      },
    },
  },

  -- ── Surround (cs, ds, ys — built-in `gc` covers comments) ──────────────
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- ── TODO / FIXME / HACK highlighting ────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix" },
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
      { "<leader>st", "<cmd>TodoTelescope<CR>", desc = "Search todos" },
      { "<leader>xt", "<cmd>TodoTrouble<CR>",   desc = "Todos (Trouble)" },
    },
  },

  -- ── Trouble: pretty list for diagnostics / quickfix / LSP locations ───
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = { focus = true },
    keys = {
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<CR>",                         desc = "Diagnostics (Trouble)" },
      { "<leader>xL", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",            desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<CR>",                 desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>",  desc = "LSP refs/defs (Trouble)" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>",                             desc = "Location list (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>",                              desc = "Quickfix list (Trouble)" },
    },
  },

  -- ── Flash: motion on steroids (s / S for leap-style jumps) ─────────────
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<C-s>", mode = { "c" },       function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },

  -- ── Comments (extra bindings on top of Neovim's built-in `gc`) ─────────
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    event = "VeryLazy",
    opts = { enable_autocmd = false },
    init = function()
      -- Hook treesitter-aware commentstring into Neovim's built-in gc.
      vim.g.skip_ts_context_commentstring_module = true
      local get_option = vim.filetype.get_option
      vim.filetype.get_option = function(filetype, option)
        return option == "commentstring"
            and require("ts_context_commentstring.internal").calculate_commentstring()
            or get_option(filetype, option)
      end
    end,
  },

  -- ── Indent context (shows `function foo()` at top when it scrolls out) ─
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { mode = "cursor", max_lines = 3 },
    keys = {
      { "<leader>ut", function()
          local tsc = require("treesitter-context")
          tsc.toggle()
          vim.notify("Treesitter context " .. (tsc.enabled() and "on" or "off"))
        end, desc = "Toggle treesitter context" },
    },
  },

  -- ── Better yank / put history with system-clipboard awareness ─────────
  {
    "gbprod/yanky.nvim",
    dependencies = { "kkharji/sqlite.lua", enabled = false },  -- pure-lua history
    event = "VeryLazy",
    opts = { ring = { history_length = 100 } },
    keys = {
      { "<leader>fy", "<cmd>YankyRingHistory<CR>", desc = "Yank history" },
      { "y",  "<Plug>(YankyYank)",          mode = { "n", "x" }, desc = "Yank" },
      { "p",  "<Plug>(YankyPutAfter)",      mode = { "n", "x" }, desc = "Put after" },
      { "P",  "<Plug>(YankyPutBefore)",     mode = { "n", "x" }, desc = "Put before" },
      { "<C-p>", "<Plug>(YankyPreviousEntry)", desc = "Cycle yank history backward" },
      { "<C-n>", "<Plug>(YankyNextEntry)",     desc = "Cycle yank history forward" },
    },
  },
}
