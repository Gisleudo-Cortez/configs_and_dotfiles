-- ============================================================================
-- lua/plugins/linting.lua
-- ----------------------------------------------------------------------------
-- nvim-lint publishes external-linter results as native vim.diagnostics.
-- Prefer LSP-provided diagnostics when a server already ships them (ruff,
-- eslint, basedpyright, zls, clang-tidy via clangd, etc.).  Listed here
-- are linters with no LSP or linters that complement LSPs.
-- ============================================================================
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    keys = { { "<leader>cL", function() require("lint").try_lint() end, desc = "Lint buffer" } },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- Shell
        sh         = { "shellcheck" },
        bash       = { "shellcheck" },
        zsh        = { "shellcheck" },
        -- fish shell lints with `fish --no-execute` built-in (LSP handles it)

        -- Markup / docs
        markdown   = { "markdownlint" },
        tex        = { "chktex" },
        plaintex   = { "chktex" },

        -- Infra
        dockerfile = { "hadolint" },
        yaml       = { "yamllint" },
        terraform  = { "tflint" },

        -- Data / DB
        sql        = { "sqlfluff" },

        -- JVM / other
        -- Ruby lint handled by solargraph/ruby_lsp if enabled
        -- PHP lint handled by intelephense
      }

      -- Trigger on the usual events
      local group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = group,
        callback = function()
          if vim.bo.buftype ~= "" then return end
          require("lint").try_lint()
        end,
      })
    end,
  },

  -- Note: linter binaries are auto-installed via mason-tool-installer
  -- (see plugins/lsp.lua) rather than a separate bridge plugin.
}
