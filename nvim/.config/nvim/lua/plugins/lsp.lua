-- ============================================================================
-- lua/plugins/lsp.lua
-- ----------------------------------------------------------------------------
-- LSP stack:
--   mason.nvim               — cross-platform installer for servers/linters/formatters
--   mason-lspconfig.nvim     — bridges mason ↔ lspconfig (auto-install list)
--   nvim-lspconfig           — ships server configs (lsp/*.lua) merged by vim.lsp.config
--
-- Pattern (Nvim 0.11+):
--   vim.lsp.config('lua_ls', { ... })   ← per-server tweaks
--   vim.lsp.enable('lua_ls')            ← activated by mason-lspconfig
-- ============================================================================
return {
  -- ── Mason: tool installer ────────────────────────────────────────────────
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    build = ":MasonUpdate",
    keys = { { "<leader>cm", "<cmd>Mason<CR>", desc = "Mason" } },
    opts = {
      ui = {
        border = "rounded",
        icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    },
  },

  -- ── mason-tool-installer: auto-install formatters / linters / DAPs ──────
  -- LSPs are handled by mason-lspconfig (below).  Mason itself doesn't
  -- auto-install non-LSP tools, so mason-tool-installer fills that gap.
  -- This is the pattern from the old config.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = {
      auto_update = false,
      run_on_start = true,
      ensure_installed = {
        -- ── Formatters ──────────────────────────────────────────────────
        "stylua", -- Lua
        "ruff", -- Python (format + lint)
        "prettierd",
        "prettier", -- JS/TS/HTML/CSS/JSON/YAML/Markdown
        "gofumpt",
        "goimports", -- Go
        "rustfmt", -- Rust
        "shfmt", -- shell
        "sqlfluff", -- SQL
        "taplo", -- TOML
        "latexindent", -- LaTeX
        "clang-format", -- C/C++/CUDA
        "google-java-format", -- Java
        "ktlint", -- Kotlin
        "black", -- fallback Python formatter
        "isort", -- fallback Python import sorter

        -- ── Linters ─────────────────────────────────────────────────────
        "shellcheck", -- bash/sh/zsh
        "markdownlint", -- markdown
        "hadolint", -- Dockerfile
        "yamllint", -- YAML
        "tflint", -- Terraform
        "chktex", -- LaTeX

        -- ── Debug adapters (DAP) ───────────────────────────────────────
        "debugpy", -- Python
        "js-debug-adapter", -- JS/TS
        "codelldb", -- C/C++/Rust
        "delve", -- Go
      },
    },
  },

  -- ── Mason ↔ lspconfig bridge ────────────────────────────────────────────
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Servers mason-lspconfig installs + enables on first launch.
      -- Install extras on demand with :MasonInstall <server-name>.
      ensure_installed = {
        -- Core data-science / finance stack
        "lua_ls",
        "basedpyright", -- Python typing
        "ruff", -- Python lint + format (as LSP)
        "texlab", -- LaTeX (financial reports / papers)
        "sqlls", -- SQL

        -- Systems / web
        "rust_analyzer", -- Rust
        "gopls", -- Go
        "ts_ls",
        "eslint", -- TypeScript / JavaScript
        "html",
        "cssls",
        "tailwindcss", -- Web
        "clangd", -- C / C++
        "zls", -- Zig

        -- JVM / other popular
        "jdtls", -- Java (basic; see nvim-jdtls for full flow)
        "kotlin_language_server", -- Kotlin
        "elixirls", -- Elixir
        "intelephense", -- PHP
        -- "ruby_lsp",                  -- uncomment if you use Ruby
        -- "omnisharp",                 -- uncomment if you use C#

        -- Config / data / markup
        "jsonls",
        "yamlls", -- JSON / YAML (with schemastore)
        "taplo", -- TOML
        "marksman", -- Markdown
        "dockerls",
        "docker_compose_language_service",
        "bashls", -- Bash

        -- Arch + Hyprland + Kitty + Fish
        "hyprls", -- Hyprland config
        "qmlls", -- QML (Qt)
        "fish_lsp", -- Fish shell
      },
      automatic_enable = true, -- vim.lsp.enable() per installed server
    },
  },

  -- ── nvim-lspconfig + per-server tweaks ──────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp", "b0o/schemastore.nvim" },
    config = function()
      -- Capabilities (blink.cmp ∪ defaults)
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities() or {}
      )
      vim.lsp.config("*", { capabilities = capabilities })

      -- Lua
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim", "Snacks" } },
            hint = { enable = true },
          },
        },
      })

      -- Python: basedpyright for typing, ruff for lint/format
      --
      -- Automatically pick the project's venv interpreter (from the old
      -- config).  Without this, basedpyright resolves imports against the
      -- system python and every `import pandas` turns red.
      local function get_python_path()
        local markers = vim.fs.find(
          { ".git", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt" },
          { upward = true }
        )[1]
        local root = markers and vim.fs.dirname(markers) or vim.fn.getcwd()
        for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python", ".venv/Scripts/python.exe" }) do
          local p = root .. "/" .. rel
          if vim.fn.executable(p) == 1 then
            return p
          end
        end
        return vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python")
          or vim.fn.exepath("python3")
          or "python"
      end

      vim.lsp.config("basedpyright", {
        settings = {
          python = { pythonPath = get_python_path() },
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoImportCompletions = true,
              diagnosticMode = "openFilesOnly",
              useLibraryCodeForTypes = true,
              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
                callArgumentNames = true,
              },
            },
          },
        },
      })
      -- ruff — PD (pandas-vet) + NPY (NumPy-specific) are useful in finance / DS
      vim.lsp.config("ruff", {
        init_options = {
          settings = {
            lint = { select = { "E", "F", "I", "B", "UP", "SIM", "PD", "NPY" } },
          },
        },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- TypeScript / JavaScript
      vim.lsp.config("ts_ls", {
        settings = {
          typescript = {
            suggest = {
              completeFunctionCalls = true,      -- fill argument placeholders on accept
              autoImports = true,
            },
            preferences = {
              importModuleSpecifier = "shortest",
              includePackageJsonAutoImports = "auto",
            },
            inlayHints = {
              includeInlayParameterNameHints = "literals",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = false,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
          javascript = {
            suggest = {
              completeFunctionCalls = true,
              autoImports = true,
            },
            preferences = {
              importModuleSpecifier = "shortest",
              includePackageJsonAutoImports = "auto",
            },
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
        },
      })

      -- Rust
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true, loadOutDirsFromCheck = true },
            checkOnSave = true,
            check = { command = "clippy", extraArgs = { "--no-deps" } },
            procMacro = { enable = true },
            inlayHints = {
              bindingModeHints        = { enable = true },
              chainingHints           = { enable = true },
              closingBraceHints       = { enable = true, minLines = 25 },
              parameterHints          = { enable = true },
              expressionAdjustmentHints = { enable = "reborrow", mode = "postfix" },
              typeHints = {
                enable                    = true,
                hideClosureInitialization = false,
                hideNamedConstructor      = false,
              },
              lifetimeElisionHints = {
                enable            = "skip_trivial",
                useParameterNames = true,
              },
            },
            hover = {
              documentation = { enable = true },
              links         = { enable = true },
            },
            completion = {
              autoimport             = { enable = true },
              autoself               = { enable = true },
              callable               = { snippets = "fill_arguments" },
              fullFunctionSignatures = { enable = true },
              postfix                = { enable = true },
            },
          },
        },
      })

      -- Go
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            completeUnimported = true,
            usePlaceholders = true,
            staticcheck = true,
            analyses = { unusedparams = true, shadow = true, fieldalignment = true },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- JSON / YAML (schemastore)
      vim.lsp.config("jsonls", {
        settings = {
          json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
        },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
            keyOrdering = false,
            format = { enable = true },
          },
        },
      })

      -- Hyprland (filetype detection lives in environment.lua)
      vim.lsp.config("hyprls", { filetypes = { "hyprlang" } })

      -- QML
      vim.lsp.config("qmlls", {
        filetypes = { "qml", "qmljs" },
        -- On Arch, the qmlls binary ships in qt6-declarative if Mason can't find it:
        --   sudo pacman -S qt6-declarative
      })

      -- Fish
      vim.lsp.config("fish_lsp", { cmd = { "fish-lsp", "start" }, filetypes = { "fish" } })

      -- LaTeX
      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            build = {
              executable = "tectonic", -- swap for "latexmk" if preferred
              args = { "-X", "compile", "%f", "--synctex", "--keep-logs", "--keep-intermediates" },
              onSave = true,
              forwardSearchAfter = true,
            },
            forwardSearch = {
              executable = "zathura", -- Arch PDF viewer of choice
              args = { "--synctex-forward", "%l:1:%f", "%p" },
            },
            chktex = { onOpenAndSave = true, onEdit = false },
          },
        },
      })

      -- Zig
      vim.lsp.config("zls", {
        settings = {
          zls = {
            enable_inlay_hints = true,
            warn_style = true,
            enable_snippets = true,               -- function-call snippets on accept
            enable_argument_placeholders = true,  -- fill argument placeholders
          },
        },
      })

      -- Java (simple jdtls; install nvim-jdtls separately for full IDE flow)
      vim.lsp.config("jdtls", {
        settings = {
          java = {
            configuration = { updateBuildConfiguration = "interactive" },
            completion = {
              favoriteStaticMembers = {
                "org.junit.jupiter.api.Assertions.*",
                "org.mockito.Mockito.*",
              },
            },
          },
        },
      })

      -- ── On-attach: buffer-local LSP keymaps ────────────────────────────
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
          map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature help")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol (alias)") -- old-config alias
          map("n", "<leader>cl", "<cmd>LspInfo<CR>", "LSP info")
          -- Diagnostic float aliases (old config used <leader>de)
          map("n", "<leader>de", vim.diagnostic.open_float, "Show diagnostic (alias)")

          if client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>uh", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "Toggle inlay hints")
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          if client:supports_method("textDocument/documentHighlight") then
            local hi_group =
              vim.api.nvim_create_augroup("user_lsp_highlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              group = hi_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr,
              group = hi_group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  { "b0o/schemastore.nvim", lazy = true, version = false },
}
