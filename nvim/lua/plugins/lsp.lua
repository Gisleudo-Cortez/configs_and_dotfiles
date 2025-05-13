-- lua/plugins/lsp.lua
return {
	-- Mason core ---------------------------------------------------------------
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ui = {
				ensure_installed = {
					"debugpy",
				},
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- Mason-LSP integration ----------------------------------------------------
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "mason.nvim" },
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
			},
			automatic_installation = true,
		},
	},

	-- nvim-lspconfig -----------------------------------------------------------
	{
		"neovim/nvim-lspconfig",
		dependencies = { "mason-lspconfig.nvim" },
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local on_attach = function(_, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				map("n", "gd", vim.lsp.buf.definition, "Definition")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				map("n", "K", vim.lsp.buf.hover, "Hover")
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code actions")
				map("n", "gr", vim.lsp.buf.references, "References")
				map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
				map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
			end

			local server_overrides = {
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
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
							},
						},
					},
				},
			}

			mason_lspconfig.setup()
			for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
				local opts = vim.tbl_deep_extend(
					"force",
					{
						on_attach = on_attach,
						capabilities = capabilities,
					},
					server_overrides[server] or {}
				)
				lspconfig[server].setup(opts)
			end
		end,
	},

	-- Optional: Virtual environment selector -----------------------------------
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			auto_refresh = true,
		},
		keys = {
			{ "<leader>vs", "<cmd>VenvSelect<cr>",       desc = "Select VirtualEnv" },
			{ "<leader>vc", "<cmd>VenvSelectCached<cr>", desc = "Use Cached VirtualEnv" },
		},
	},
}
