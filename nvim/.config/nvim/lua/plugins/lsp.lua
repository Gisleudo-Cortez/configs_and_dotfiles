-- lua/plugins/lsp.lua

return {
	-- 1. Mason: installer for LSP/DAP/linters/formatters
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
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- 2. nvim-lspconfig: The core LSP configuration capabilities.
	{ "neovim/nvim-lspconfig" },

	-- 3. mason-lspconfig: Bridge between Mason and lspconfig.
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		-- The entire setup is now handled within this single config function.
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Define the on_attach function once.
			-- This runs for each buffer that gets an LSP attached.
			local on_attach = function(client, bufnr)
				local function bufmap(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				-- LSP keymaps
				bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				bufmap("n", "K", vim.lsp.buf.hover, "Hover")
				bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
				bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				bufmap("n", "gr", vim.lsp.buf.references, "References")
			end

			-- A table to hold server-specific settings
			local servers = {
				lua_ls = {
					settings = { Lua = { diagnostics = { globals = { "vim" } } } },
				},
				pyright = {
					settings = {
						python = {
							pythonPath = (function()
								local cwd = vim.fn.getcwd()
								if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
									return cwd .. "/.venv/bin/python"
								end
								return vim.fn.exepath("python") or "python"
							end)(),
						},
					},
				},
				ruff = {
					init_options = { settings = { args = {} } },
				},
				rust_analyzer = {}, -- Use defaults
			}

			-- **The single, correct setup call.**
			-- We pass ensure_installed and handlers directly to the setup function.
			mason_lspconfig.setup({
				ensure_installed = {
					"rust_analyzer", "pyright", "ruff", "gopls", "ts_ls", "lua_ls",
					"bashls", "sqlls", "cssls", "html", "jsonls", "yamlls",
					"marksman", "dockerls", "jdtls",
				},
				automatic_installation = true,
				-- This is the key: handlers are defined inside the setup call.
				handlers = {
					-- The default handler for all servers.
					function(server_name)
						local server_config = servers[server_name] or {}

						-- Combine defaults with server-specific settings
						local final_opts = vim.tbl_deep_extend("force", {
							on_attach = on_attach,
							capabilities = capabilities,
						}, server_config)

						lspconfig[server_name].setup(final_opts)
					end,
				},
			})

			-- Configure diagnostics UI
			vim.diagnostic.config({
				underline = true,
				virtual_text = { spacing = 2, prefix = "●" },
				signs = true,
				severity_sort = true,
			})
		end,
	},
}
