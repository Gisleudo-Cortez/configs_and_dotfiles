-- ============================================================================
-- lua/plugins/ui.lua
-- ----------------------------------------------------------------------------
-- UI polish:
--   lualine         — statusline
--   which-key       — popup help for leader combos
--   noice           — modern cmdline / messages / notifications
--   mini.icons      — icon provider (used by many plugins)
--   nvim-web-devicons — fallback icon provider for plugins that need it
-- ============================================================================
return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons" },
    opts = function()
      return {
        options = {
          theme = "tokyonight",
          globalstatus = true,
          component_separators = { left = "│", right = "│" },
          section_separators   = { left = "",  right = ""  },
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            { "diagnostics",
              symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1, symbols = { modified = " [+]", readonly = " [RO]", unnamed = "[No Name]" } },
          },
          lualine_x = {
            { function()
                local ok, clients = pcall(vim.lsp.get_clients, { bufnr = 0 })
                if not ok or #clients == 0 then return "" end
                return " " .. table.concat(vim.tbl_map(function(c) return c.name end, clients), ",")
              end,
              color = { fg = "#7aa2f7" } },
            "encoding", "fileformat",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        -- ── Tabline: show each open buffer as a tab with its relative path ──
        -- Ported from the old config's lualine tabline.  `show_filename_only
        -- = false` makes lualine print the file path (relative to cwd).  The
        -- `fmt` function keeps the path compact: for deep trees it collapses
        -- middle dirs to `…` (e.g. `src/…/utils/loader.py`).
        tabline = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              "buffers",
              show_filename_only      = false,    -- <- show path, not just name
              hide_filename_extension = false,
              show_modified_status    = true,
              mode                    = 0,         -- 0 = name only (we override via fmt)
              max_length              = function() return vim.o.columns * 2 / 3 end,
              filetype_names = {
                snacks_dashboard  = "Dashboard",
                snacks_explorer   = "Explorer",
                snacks_picker_list= "Picker",
                lazy              = "Lazy",
                mason             = "Mason",
                TelescopePrompt   = "Telescope",
                dbui              = "DBUI",
                dbout             = "DB output",
              },
              buffers_color = {
                -- theme-aware colours so swapping colorscheme still looks fine
                active   = "lualine_a_normal",
                inactive = "lualine_b_inactive",
              },
              symbols = {
                modified       = " ●",
                alternate_file = "",          -- no `#` marker
                directory      = "",
              },
              -- Smart path formatter:
              --   "/home/u/proj/src/a/b/c/file.lua" (cwd=/home/u/proj)
              --   → "src/…/c/file.lua"   when path would be > 40 chars
              --   → "src/a/b/c/file.lua" otherwise
              fmt = function(name, context)
                local bufnr = context.bufnr
                local path  = vim.api.nvim_buf_get_name(bufnr)
                if path == "" or vim.bo[bufnr].buftype ~= "" then return name end
                local rel = vim.fn.fnamemodify(path, ":.")
                if #rel <= 40 then return rel end
                local parts = vim.split(rel, "/")
                if #parts <= 3 then return rel end
                return parts[1] .. "/…/" .. parts[#parts - 1] .. "/" .. parts[#parts]
              end,
            },
          },
          lualine_x = {},
          lualine_y = {},
          lualine_z = { "tabs" },        -- tab-page indicator on the right
        },
        extensions = { "lazy", "mason", "quickfix", "trouble", "nvim-dap-ui" },
      }
    end,
  },

  -- Which-key — popup legend for leader mappings
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",         -- "classic" | "modern" | "helix"
      delay = 400,
      spec = {
        { "<leader>b", group = "buffers" },
        { "<leader>c", group = "code"    },
        { "<leader>d", group = "debug"   },
        { "<leader>f", group = "find"    },
        { "<leader>g", group = "git"     },
        { "<leader>gh",group = "hunks"   },
        { "<leader>s", group = "search"  },
        { "<leader>u", group = "toggle"  },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Keymaps (which-key)" },
    },
  },

  -- Modern cmdline / messages / notifications replacement
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,          -- classic bottom cmdline for :/?
        command_palette = true,        -- floating cmdline + popupmenu
        long_message_to_split = true,  -- long messages go to split
        lsp_doc_border = true,
      },
      routes = {
        -- hide 'written' / 'lines yanked' chatter
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
      },
    },
    keys = {
      { "<leader>sn", "", desc = "+noice" },
      { "<leader>snl", function() require("noice").cmd("last")    end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all")     end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<C-f>",       function() if not require("noice.lsp").scroll(4)  then return "<C-f>" end end, silent = true, expr = true, desc = "Scroll Forward",  mode = { "i", "n", "s" } },
      { "<C-b>",       function() if not require("noice.lsp").scroll(-4) then return "<C-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = { "i", "n", "s" } },
    },
  },

  -- Icons (modern, lightweight, preferred over nvim-web-devicons)
  {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- Better vim.ui (select / input) — already provided by snacks.input, but
  -- keeping dressing.nvim around as a safety net for plugins that hard-require
  -- vim.ui.select/input replacements. Commented out by default.
  -- { "stevearc/dressing.nvim", lazy = true, opts = {} },
}
