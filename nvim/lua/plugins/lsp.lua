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

			-- Common capabilities and on_attach for LSP servers
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
			}

			mason_lspconfig.setup() -- ensure the servers above are installed
			for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
				local opts = vim.tbl_deep_extend("force", default_opts, server_settings[server] or {})
				lspconfig[server].setup(opts)
			end
		end,
	},
	-- Rust enhancements (using rust-tools)
	{
		"simrat39/rust-tools.nvim",
		ft = "rust",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			local rt = require("rust-tools")
			local mason_registry = require("mason-registry")
			local codelldb = mason_registry.get_package("codelldb")
			if not codelldb or not codelldb:is_installed() then
				vim.notify("Mason: please install codelldb for Rust debugging", vim.log.levels.WARN)
				return
			end
			local extension_path = codelldb:get_install_path() .. "/extension/"
			local codelldb_path = extension_path .. "adapter/codelldb"
			local liblldb_path = extension_path .. "lldb/lib/liblldb.so"
			rt.setup({
				server = {
					on_attach = function(_, bufnr)
						vim.keymap.set("n", "K", rt.hover_actions.hover_actions,
							{ buffer = bufnr, desc = "Rust Hover" })
						vim.keymap.set("n", "<leader>ca", rt.code_action_group.code_action_group,
							{ buffer = bufnr, desc = "Rust Code Actions" })
					end,
				},
				dap = {
					adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path,
						liblldb_path),
				},
			})
		end,
	},
}
