-- ============================================================================
-- lua/plugins/database.lua
-- ----------------------------------------------------------------------------
-- vim-dadbod stack — a proper SQL IDE inside Neovim.
--
-- Typical finance / DS workflow:
--   :DBUI                  ← opens the connections drawer
--   pick a connection      ← drops you in a scratch query buffer
--   write SQL, <leader>S   ← run the selection / query
--   results open in a split
--
-- Connection URLs live either in ~/.local/share/db_ui/connections.json
-- (added via :DBUIAddConnection), or via vim.g.dbs for per-session setup,
-- or in a .env file at the project root (DBUI_URL / DB_UI_<name>).
--
-- Example connections (put in a gitignored file or $XDG_CONFIG_HOME/nvim/lua/local.lua):
--   vim.g.dbs = {
--     prices   = "duckdb:/data/prices.duckdb",                -- DuckDB (great for finance)
--     warehouse= "postgres://user:pw@host:5432/warehouse",    -- PostgreSQL
--     sqlite   = "sqlite:/data/research.sqlite",              -- SQLite
--     -- snowflake = "snowflake://user:pw@account/db/schema?warehouse=WH",
--     -- bigquery  = "bigquery://project/dataset",
--   }
-- ============================================================================
return {
  -- Core: :DB command, connection adapters
  {
    "tpope/vim-dadbod",
    lazy = true,
    cmd = { "DB" },
  },

  -- UI: sidebar tree + saved queries
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>Du", "<cmd>DBUIToggle<CR>",           desc = "Toggle DB UI" },
      { "<leader>Da", "<cmd>DBUIAddConnection<CR>",    desc = "Add DB connection" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<CR>",       desc = "Find DB buffer" },
      { "<leader>Dr", "<cmd>DBUIRenameBuffer<CR>",     desc = "Rename DB buffer" },
      { "<leader>Dl", "<cmd>DBUILastQueryInfo<CR>",    desc = "Last query info" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts       = 1
      vim.g.db_ui_show_database_icon   = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position         = "left"
      vim.g.db_ui_winwidth             = 40
      vim.g.db_ui_use_nvim_notify      = 1
      -- Where DBUI saves your adhoc connections and queries.
      -- Under $XDG_DATA_HOME so it follows the rest of nvim state.
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      -- Treat these FTs as SQL inside DBUI
      vim.g.db_ui_table_helpers = {
        postgresql = { Count = "SELECT COUNT(*) FROM \"{optional_schema}{table}\"" },
      }
      -- Auto-attach completion source to SQL buffers
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          vim.keymap.set(
            { "n", "v", "x" }, "<leader>S",
            function() vim.cmd("DB") end,
            { buffer = true, desc = "Run SQL query" }
          )
        end,
      })
    end,
  },
}
