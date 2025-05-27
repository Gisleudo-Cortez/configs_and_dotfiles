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
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local on_attach = function(_, bufnr)
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
			end

			local function get_python_path()
				local cwd = vim.fn.getcwd()
				if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
					return cwd .. "/.venv/bin/python"
				end
				return vim.fn.exepath("python") or "python"
			end

			local default_opts = {
				on_attach = on_attach,
				capabilities = capabilities,
			}
			local server_settings = {
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
						},
					},
				},
				pyright = {
					settings = {
						python = {
							pythonPath = get_python_path(),
						},
					},
				},
			}

			mason_lspconfig.setup()
			for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
				local opts = vim.tbl_deep_extend("force", default_opts, server_settings[server] or {})
				lspconfig[server].setup(opts)
			end

			-- Updated: use 'ruff' instead of deprecated 'ruff-lsp'
			lspconfig.ruff.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				init_options = { settings = { args = {} } },
			})
		end,
	},
}
