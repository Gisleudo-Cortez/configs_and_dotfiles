-- lua/plugins/lsp.lua
return {
	-- 1. Mason: installer for LSP/DAP/linters/formatters
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ensure_installed = { "debugpy", "pyright", "ruff" },
		},
	},

	-- 2. Mason LSP Config & Server Setup
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Helper: Find the correct python path for uv/venv
			local function get_python_path(workspace)
				-- 1. Look for a .venv in the current project
				local venv_path = vim.fs.joinpath(workspace, ".venv", "bin", "python")
				if vim.fn.executable(venv_path) == 1 then
					return venv_path
				end
				-- 2. Fallback to system python
				return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
			end

			local on_attach = function(_, bufnr)
				local function bufmap(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				bufmap("n", "K", vim.lsp.buf.hover, "Hover")
				bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
				bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				bufmap("n", "gr", vim.lsp.buf.references, "References")
			end

			mason_lspconfig.setup({
				ensure_installed = { "pyright", "ruff", "lua_ls" },
				handlers = {
					function(server_name)
						local opts = {
							on_attach = on_attach,
							capabilities = capabilities,
						}

						-- Specific config for Pyright to use the detected venv
						if server_name == "pyright" then
							opts.before_init = function(_, config)
								config.settings.python.pythonPath = get_python_path(
								config.root_dir)
							end
						end

						lspconfig[server_name].setup(opts)
					end,
				},
			})
		end,
	},
}
