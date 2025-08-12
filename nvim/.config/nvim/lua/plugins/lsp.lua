-- LSP servers, LSP configurations, and language-specific enhancements
return {
	-- Mason: installer for LSP, DAP, linters, formatters
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ensure_installed = {
				"debugpy",
				"codelldb",
				"js-debug-adapter",
				"pyright",
				"ruff",
			},
			ui = {
				icons = {
					package_installed   = "✓",
					package_pending     = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"rust_analyzer",
				"pyright",
				"ruff",
				"gopls",
				"ts_ls",
				"lua_ls",
				"bashls",
				"sqlls",
				"cssls",
				"html",
				"jsonls",
				"yamlls",
				"marksman",
				"dockerls",
				"jdtls",
			},
			automatic_installation = true,
		},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
		config = function()
			-- Global diagnostics UI
			vim.diagnostic.config({
				underline = true,
				virtual_text = { spacing = 2, prefix = "●" },
				signs = true,
				severity_sort = true,
			})

			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local on_attach = function(client, bufnr)
				local bufmap = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
				bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
				bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
				bufmap("n", "gr", vim.lsp.buf.references, "Go to References")
				bufmap("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
				bufmap("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
				bufmap("i", "<C-h>", vim.lsp.buf.signature_help, "Signature Help")

				if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					vim.lsp.inlay_hint(bufnr, true)
				end
			end

			local function get_python_path()
				local cwd = vim.fn.getcwd()
				if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
					return cwd .. "/.venv/bin/python"
				end
				return vim.fn.exepath("python") or "python"
			end

			mason_lspconfig.setup()

			mason_lspconfig.setup_handlers({
				-- default handler for all servers
				function(server)
					lspconfig[server].setup({
						on_attach = on_attach,
						capabilities = capabilities,
					})
				end,

				-- overrides
				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						settings = { Lua = { diagnostics = { globals = { "vim" } } } },
					})
				end,

				["pyright"] = function()
					lspconfig.pyright.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						settings = { python = { pythonPath = get_python_path() } },
					})
				end,

				["ruff"] = function()
					lspconfig.ruff.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						init_options = { settings = { args = {} } },
					})
				end,
			})
		end,
	},
}
