-- ============================================================================
-- lua/plugins/formatting.lua
-- ----------------------------------------------------------------------------
-- conform.nvim — format-on-save for every language in the stack.
-- See :ConformInfo for the list of what's wired up for the current buffer.
-- ============================================================================

---@type table<string, (string[]|conform.FormatterUnit[])>
local formatters_by_ft = {
  -- Lua
  lua        = { "stylua" },

  -- Python (ruff replaces isort + black in one pass)
  python     = { "ruff_organize_imports", "ruff_format" },

  -- Data science / finance ----------------------------------------------
  r          = { "styler" },
  rmd        = { "styler" },
  quarto     = { "injected" },               -- format code cells in .qmd via otter/treesitter
  sql        = { "sqlfluff" },
  tex        = { "latexindent" },
  plaintex   = { "latexindent" },
  bib        = { "bibtex-tidy" },

  -- JS / TS / web (prettierd = daemon; prettier is fallback)
  javascript      = { "prettierd", "prettier", stop_after_first = true },
  javascriptreact = { "prettierd", "prettier", stop_after_first = true },
  typescript      = { "prettierd", "prettier", stop_after_first = true },
  typescriptreact = { "prettierd", "prettier", stop_after_first = true },
  vue             = { "prettierd", "prettier", stop_after_first = true },
  svelte          = { "prettierd", "prettier", stop_after_first = true },
  astro           = { "prettierd", "prettier", stop_after_first = true },
  html            = { "prettierd", "prettier", stop_after_first = true },
  css             = { "prettierd", "prettier", stop_after_first = true },
  scss            = { "prettierd", "prettier", stop_after_first = true },
  less            = { "prettierd", "prettier", stop_after_first = true },
  json            = { "prettierd", "prettier", stop_after_first = true },
  jsonc           = { "prettierd", "prettier", stop_after_first = true },
  yaml            = { "prettierd", "prettier", stop_after_first = true },
  markdown        = { "prettierd", "prettier", stop_after_first = true },
  graphql         = { "prettierd", "prettier", stop_after_first = true },

  -- QML (Qt ships with qmlformat)
  qml        = { "qmlformat" },

  -- Systems / compiled
  rust       = { "rustfmt", lsp_format = "fallback" },
  go         = { "goimports", "gofumpt" },
  c          = { "clang_format" },
  cpp        = { "clang_format" },
  zig        = { "zigfmt" },
  cuda       = { "clang_format" },

  -- JVM
  java       = { "google-java-format" },
  kotlin     = { "ktlint" },
  scala      = { "scalafmt" },

  -- Other popular
  ruby       = { "rubocop" },
  php        = { "php_cs_fixer" },
  elixir     = { "mix" },                     -- mix format (requires mix in PATH)
  haskell    = { "fourmolu" },
  nix        = { "nixfmt" },
  -- csharp  = { "csharpier" },               -- uncomment if you work in C#

  -- Shell / config
  sh         = { "shfmt" },
  bash       = { "shfmt" },
  zsh        = { "shfmt" },
  fish       = { "fish_indent" },             -- ships with fish itself
  toml       = { "taplo" },
  dockerfile = { "hadolint" },                -- hadolint only lints; no fmt
  hyprlang   = { "hyprlang-fmt" },            -- optional; safe no-op if missing
  nginx      = { "nginxbeautifier" },

  -- Fallback: any filetype → trim whitespace + final newline
  ["_"]      = { "trim_whitespace", "trim_newlines" },
}

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd  = { "ConformInfo" },
    keys = {
      { "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" }, desc = "Format buffer / selection" },
      { "<leader>fm",                                                  -- old-config alias
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" }, desc = "Format (alias)" },
      { "<leader>uf", function()
          if vim.b.disable_autoformat or vim.g.disable_autoformat then
            vim.b.disable_autoformat = false; vim.g.disable_autoformat = false
            vim.notify("Autoformat enabled", vim.log.levels.INFO)
          else
            vim.b.disable_autoformat = true
            vim.notify("Autoformat disabled (buffer)", vim.log.levels.WARN)
          end
        end, desc = "Toggle autoformat (buffer)" },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
      -- Per-formatter tweaks
      formatters = {
        shfmt         = { prepend_args = { "-i", "2", "-ci" } },
        stylua        = { prepend_args = { "--column-width", "100", "--indent-width", "2", "--indent-type", "Spaces" } },
        sqlfluff      = { prepend_args = { "--dialect", "ansi" } },
        latexindent   = { prepend_args = { "-l", "-m" } },     -- local config, modify-line-breaks
        -- hyprlang-fmt is not packaged; mark as optional so conform doesn't error
        ["hyprlang-fmt"] = { condition = function() return vim.fn.executable("hyprlang-fmt") == 1 end },
      },
    },
  },

  -- Note: formatters and linters are auto-installed via the
  -- WhoIsSethDaniel/mason-tool-installer.nvim spec in plugins/lsp.lua.
  -- That gives us a single, explicit list of "what to install" instead of
  -- depending on archived bridge plugins (zapling/mason-conform was archived
  -- in 2025, and rshkarin/mason-nvim-lint has fragmented forks).
}
