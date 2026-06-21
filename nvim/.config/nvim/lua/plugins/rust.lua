-- ============================================================================
-- lua/plugins/rust.lua
-- ----------------------------------------------------------------------------
-- rustaceanvim — Rust IDE: LSP (rust-analyzer), DAP (codelldb), formatters,
-- and other Rust-specific niceties.  rustaceanvim manages its own LSP
-- attachment, so it overrides the rust_analyzer config in lsp.lua for Rust
-- buffers — that's intentional.  The lsp.lua config still serves as fallback
-- for any non-rustaceanvim path.
--
-- codelldb must be installed via Mason (already in ensure_installed in
-- lsp.lua's mason-tool-installer).  rust-analyzer is also in mason-lspconfig
-- ensure_installed.
-- ============================================================================
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    init = function()
      vim.g.rustaceanvim = {
        server = {
          cmd = { "rust-analyzer" },
          default_settings = {
            ["rust-analyzer"] = {
              check = {
                extraArgs = { "--target-dir", "/tmp/rust-analyzer-check" },
              },
              diagnostics = {
                experimental = { enable = true },
              },
            },
          },
        },
        dap = {
          adapter = {
            type = "server",
            port = "${port}",
            executable = {
              command = "codelldb",
              args = { "--port", "${port}" },
            },
          },
        },
      }
    end,
  },
}