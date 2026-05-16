-- ============================================================================
-- lua/plugins/snacks.lua
-- ----------------------------------------------------------------------------
-- folke/snacks.nvim is a single plugin bundling ~20 QoL modules.
-- We enable the most useful ones:
--   picker     — fast fuzzy finder (Telescope replacement)
--   explorer   — sidebar file tree (Neo-tree replacement)
--   dashboard  — start screen
--   notifier   — pretty vim.notify
--   input      — nicer vim.ui.input
--   lazygit    — terminal lazygit integration
--   indent     — indent guides + scope
--   scope      — treesitter-aware scope highlighting
--   bigfile    — disable expensive features on huge files
--   quickfile  — render file fast before plugins load
--   scroll     — smooth scrolling
--   words      — LSP reference highlight on cursor-hold
--   statuscolumn — combined sign + number column
-- ============================================================================
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile     = {
      enabled = true,
      ---@param ctx {buf: number, ft:string}
      setup = function(ctx)
        -- Disable indent guides and scope on big files.
        -- Without this, indent/scope try to parse treesitter on huge buffers
        -- and crash with "attempt to call method 'range' (a nil value)".
        vim.b[ctx.buf].snacks_indent = false
        vim.b[ctx.buf].snacks_scope = false
      end,
    },
    dashboard   = {
      enabled = true,
      preset = {
        header = [[
   ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
   ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
   ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
   ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
      },
    },
    explorer    = { enabled = true, hidden = true },
    indent      = {
      enabled = true,
      -- Block injection-heavy filetypes that trigger Neovim 0.12's
      -- async injection crash (languagetree.lua:215: range nil).
      -- Also guard against bigfile buffers and explicit disables.
      filter = function(buf)
        local ft = vim.bo[buf].filetype
        local ts_crash_fts = { markdown = true, quarto = true, rmd = true, rnoweb = true }
        if ts_crash_fts[ft] then return false end
        return vim.g.snacks_indent ~= false
          and vim.b[buf].snacks_indent ~= false
          and vim.bo[buf].buftype == ""
          and ft ~= "bigfile"
      end,
    },
    input       = { enabled = true },
    notifier    = { enabled = true, timeout = 3000 },
    picker      = {
      enabled = true,
      ui_select = true,   -- replace vim.ui.select with snacks picker
      win = {
        input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } },
      },
    },
    quickfile   = { enabled = true },
    scope       = { enabled = true },
    scroll      = { enabled = true },
    statuscolumn= { enabled = true },
    words       = { enabled = true },
  },
  keys = {
    -- ── Picker (find / grep / buffers) ────────────────────────────────────
    { "<leader><space>", function() Snacks.picker.smart() end,      desc = "Smart find files"      },
    { "<leader>ff",      function() Snacks.picker.files() end,      desc = "Find files"            },
    { "<leader>fg",      function() Snacks.picker.grep() end,       desc = "Grep (live)"           },
    { "<leader>fw",      function() Snacks.picker.grep_word() end,  desc = "Grep word under cursor", mode = { "n", "x" } },
    { "<leader>fb",      function() Snacks.picker.buffers() end,    desc = "Buffers"               },
    { "<leader>fr",      function() Snacks.picker.recent() end,     desc = "Recent files"          },
    { "<leader>fh",      function() Snacks.picker.help() end,       desc = "Help tags"             },
    { "<leader>fk",      function() Snacks.picker.keymaps() end,    desc = "Keymaps"               },
    { "<leader>fc",      function() Snacks.picker.commands() end,   desc = "Commands"              },
    { "<leader>fR",      function() Snacks.picker.resume() end,     desc = "Resume last picker"    },
    { "<leader>fn",      function() Snacks.picker.notifications() end, desc = "Notifications"      },
    { "<leader>:",       function() Snacks.picker.command_history() end, desc = "Command history"  },
    { "<leader>/",       function() Snacks.picker.grep_buffers() end,   desc = "Grep open buffers" },

    -- ── LSP pickers (using snacks picker instead of telescope) ────────────
    { "gd",              function() Snacks.picker.lsp_definitions() end,      desc = "Goto definition"      },
    { "gr",              function() Snacks.picker.lsp_references() end, nowait = true, desc = "References"   },
    { "gI",              function() Snacks.picker.lsp_implementations() end,  desc = "Goto implementation"  },
    { "gy",              function() Snacks.picker.lsp_type_definitions() end, desc = "Goto type definition" },
    { "<leader>ss",      function() Snacks.picker.lsp_symbols() end,          desc = "LSP symbols"          },
    { "<leader>sS",      function() Snacks.picker.lsp_workspace_symbols() end,desc = "Workspace symbols"    },

    -- ── Diagnostics picker ────────────────────────────────────────────────
    { "<leader>xx",      function() Snacks.picker.diagnostics() end,          desc = "Workspace diagnostics" },
    { "<leader>xX",      function() Snacks.picker.diagnostics_buffer() end,   desc = "Buffer diagnostics"    },

    -- ── Explorer (file tree) ──────────────────────────────────────────────
    { "<leader>e",       function() Snacks.explorer() end,          desc = "File explorer"         },

    -- ── Git ──────────────────────────────────────────────────────────────
    { "<leader>gg",      function() Snacks.lazygit() end,           desc = "Lazygit"               },
    { "<leader>gl",      function() Snacks.lazygit.log() end,       desc = "Lazygit log"           },
    { "<leader>gL",      function() Snacks.lazygit.log_file() end,  desc = "Lazygit log (file)"    },
    { "<leader>gb",      function() Snacks.picker.git_branches() end, desc = "Git branches"        },
    { "<leader>gs",      function() Snacks.picker.git_status() end, desc = "Git status"            },
    { "<leader>gd",      function() Snacks.picker.git_diff() end,   desc = "Git diff (hunks)"      },
    { "<leader>gB",      function() Snacks.gitbrowse() end,         desc = "Open in browser", mode = { "n", "v" } },

    -- ── Misc ─────────────────────────────────────────────────────────────
    { "<leader>n",       function() Snacks.notifier.show_history() end, desc = "Notification history" },
    { "<leader>bD",      function() Snacks.bufdelete() end,             desc = "Delete buffer (keep window)" },
    { "<leader>cR",      function() Snacks.rename.rename_file() end,    desc = "Rename file" },
    { "<leader>.",       function() Snacks.scratch() end,               desc = "Scratch buffer" },
    { "<leader>S",       function() Snacks.scratch.select() end,        desc = "Select scratch" },
    { "<leader>z",       function() Snacks.zen() end,                   desc = "Zen mode" },
    { "<c-/>",           function() Snacks.terminal() end,              desc = "Toggle terminal" },
    { "]]",              function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference", mode = { "n", "t" } },
    { "[[",              function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference", mode = { "n", "t" } },
  },
  init = function()
    -- Guard: prevent indent/scope treesitter crash on large files.
    -- BufReadPost fires before FileType 'bigfile' in many cases, so
    -- scope.attach() tries to parse treesitter before bigfile.setup
    -- can set the buffer vars. This BufReadPre handler runs first
    -- (init > config in lazy.nvim) and blocks the parse before it starts.
    vim.api.nvim_create_autocmd("BufReadPre", {
      pattern = "*",
      callback = function(ev)
        local ok, size = pcall(vim.fn.getfsize, ev.file)
        if ok and size > 1.5 * 1024 * 1024 then
          vim.b.snacks_indent = false
          vim.b.snacks_scope = false
        end
      end,
    })

    -- Route vim.notify through snacks on startup so early errors are pretty
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        _G.dd    = function(...) Snacks.debug.inspect(...) end
        _G.bt    = function()    Snacks.debug.backtrace() end
        vim.print = _G.dd
      end,
    })
  end,
}
