-- ============================================================================
-- lua/plugins/treesitter.lua
-- ----------------------------------------------------------------------------
-- Syntax, indent, folding, and textobjects powered by tree-sitter.
-- Parsers are installed to stdpath("data")/lazy/… on first use; update with :TSUpdate
-- ============================================================================
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
        "lua", "luadoc", "luap", "vim", "vimdoc", "query", "regex", "diff",

        -- Markup / docs / data
        "markdown", "markdown_inline", "latex", "bibtex", "rst",
        "html", "css", "scss", "xml",
        "json", "jsonc", "yaml", "toml", "kdl",
        "csv", "tsv",

        -- Shell / config
        "bash", "fish",                     -- fish for your shell
        "dockerfile", "make", "cmake", "ninja", "ini",
        "gitignore", "gitcommit", "git_config", "git_rebase", "gitattributes",
        "ssh_config",

        -- Arch + Hyprland + Kitty + Fish ecosystem
        "hyprlang",                         -- Hyprland config
        "kdl",                              -- used by zellij / some config formats
        "nix",                              -- nix-based dev shells

        -- Data science / finance core
        "python",                           -- Python
        "r", "rnoweb",                      -- R + Rnoweb (knitr)
        "sql",                              -- SQL
        "jq",                               -- jq (for JSON/financial API wrangling)
        "awk",                              -- awk (quick text munging)

        -- Systems / compiled
        "rust",
        "go", "gomod", "gosum", "gowork",
        "c", "cpp",
        "zig",
        "cuda",                             -- GPU-accelerated DS workloads

        -- JVM / other popular
        "java", "kotlin", "scala",
        "c_sharp",
        "elixir", "heex", "eex",
        "ruby",
        "php",
        "haskell",

        -- Web / frontend
        "javascript", "typescript", "tsx", "jsdoc",
        "vue", "svelte", "astro",
        "graphql", "prisma",

        -- Qt
        "qmljs",                            -- QML

        -- Infra
        "terraform", "hcl",
        "helm",
        "nginx",

        -- Misc
        "dot", "mermaid",                   -- Graphviz / Mermaid diagrams
        "requirements",                     -- pip requirements.txt
      },
      auto_install = true,
      sync_install = false,
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true, disable = { "python", "yaml" } },
      -- Incremental selection (ported from old config).
      -- <C-space>  — start / expand to next node
      -- <BS>       — shrink to previous node
      -- <M-space>  — select containing scope
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-space>",
          node_incremental  = "<C-space>",
          scope_incremental = "<M-space>",
          node_decremental  = "<BS>",
        },
      },
      textobjects = {
        select = {
          enable = true, lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",["ia"] = "@parameter.inner",
            ["ai"] = "@conditional.outer",["ii"] = "@conditional.inner",
            ["al"] = "@loop.outer",     ["il"] = "@loop.inner",
          },
        },
        move = {
          enable = true, set_jumps = true,
          goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      -- Treesitter-backed folds
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
    end,
  },
}
