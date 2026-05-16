-- ============================================================================
-- lua/plugins/treesitter.lua
-- ----------------------------------------------------------------------------
-- Syntax, indent, folding, and textobjects powered by tree-sitter.
-- Parsers are installed to stdpath("data")/lazy/… on first use; update with :TSUpdate
--
-- Neovim 0.12.x injection engine bug: async injection processing crashes
-- when it encounters injected languages (e.g. code blocks in markdown,
-- chunks in quarto, R noweb).  The crash fires across the highlighter,
-- scope analysis, and indent-guide layers.
--
-- Mitigation: disable ALL treesitter features on the known crash-trigger
-- filetypes.  They fall back to Neovim's built-in regex syntax engine.
-- Once Neovim upstream fixes the injection engine, remove from disable lists.
-- ============================================================================

-- Filetypes where Neovim 0.12.x injection crashes.  Disable TS there.
local TS_CRASH_FTS = { "markdown", "quarto", "rmd", "rnoweb" }

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    cmd = { "TSUpdate", "TSUpdateSync", "TSInstall", "TSInstallSync", "TSInstallInfo" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = {
        -- Nvim / embedded
        "lua",
        "luadoc",
        "luap",
        "vim",
        "vimdoc",
        "query",
        "regex",
        "diff",

        -- Markup / docs / data
        "markdown",
        "markdown_inline",
        "bibtex",
        "rst",
        "html",
        "css",
        "scss",
        "xml",
        "json",
        "yaml",
        "toml",
        "kdl",
        "csv",
        "tsv",

        -- Shell / config
        "bash",
        "fish", -- fish for your shell
        "dockerfile",
        "make",
        "cmake",
        "ninja",
        "ini",
        "gitignore",
        "gitcommit",
        "git_config",
        "git_rebase",
        "gitattributes",
        "ssh_config",

        -- Arch + Hyprland + Kitty + Fish ecosystem
        "hyprlang", -- Hyprland config
        "kdl", -- used by zellij / some config formats
        "nix", -- nix-based dev shells

        -- Data science / finance core
        "python", -- Python
        "r",
        "rnoweb", -- R + Rnoweb (knitr)
        "sql", -- SQL
        "jq", -- jq (for JSON/financial API wrangling)
        "awk", -- awk (quick text munging)

        -- Systems / compiled
        "rust",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "c",
        "cpp",
        "zig",
        "cuda", -- GPU-accelerated DS workloads

        -- JVM / other popular
        "java",
        "kotlin",
        "scala",
        "c_sharp",
        "elixir",
        "heex",
        "eex",
        "ruby",
        "php",
        "haskell",

        -- Web / frontend
        "javascript",
        "typescript",
        "tsx",
        "jsdoc",
        "vue",
        "svelte",
        "astro",
        "graphql",
        "prisma",

        -- Qt
        "qmljs", -- QML

        -- Infra
        "terraform",
        "hcl",
        "helm",
        "nginx",

        -- Misc
        "dot",
        "mermaid", -- Graphviz / Mermaid diagrams
        "requirements", -- pip requirements.txt
      },
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        -- Neovim 0.12.x: disable TS highlight on injection-crash filetypes.
        -- They fall back to built-in regex syntax engine.
        disable = TS_CRASH_FTS,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
        -- Python/YAML have perma-indent issues; injection FTs crash 0.12.x.
        disable = vim.list_extend({ "python", "yaml" }, TS_CRASH_FTS),
      },
      -- Incremental selection (ported from old config).
      -- <C-space>  — start / expand to next node
      -- <BS>       — shrink to previous node
      -- <M-space>  — select containing scope
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<M-space>",
          node_decremental = "<BS>",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      -- Treesitter-backed folds. The pcall wrapper swallows nil-node errors
      -- that fire when formatters rewrite the buffer mid-parse.
      _G.safe_ts_foldexpr = function()
        local ok, val = pcall(vim.treesitter.foldexpr)
        return ok and val or "0"
      end
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.safe_ts_foldexpr()"
    end,
  },
}
