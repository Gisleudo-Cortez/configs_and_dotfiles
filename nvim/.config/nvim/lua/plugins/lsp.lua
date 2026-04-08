-- lua/plugins/lsp.lua
return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ensure_installed = { "debugpy" }, -- Only non-LSP tools here
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp", -- Ensure capabilities are available
		},
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Robust Python Path Detection
			local function get_python_path()
				local root = vim.fs.dirname(vim.fs.find({ '.git', 'pyproject.toml', 'setup.py' },
					{ upward = true })[1])
				if root then
					local venv_paths = {
						vim.fs.joinpath(root, ".venv", "bin", "python"),
						vim.fs.joinpath(root, "venv", "bin", "python"),
					}
					for _, path in ipairs(venv_paths) do
						if vim.fn.executable(path) == 1 then return path end
					end
				end
				return vim.fn.exepath("python3") or "python"
			end

			local on_attach = function(client, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
				end

				-- Standard Navigation
				map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				map("n", "gr", vim.lsp.buf.references, "References")
				map("n", "gI", vim.lsp.buf.implementation, "Implementation")
				map("n", "K", vim.lsp.buf.hover, "Hover Documentation")

				-- Editing
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")

				-- Diagnostics (Modern addition)
				map("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
				map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
				map("n", "<leader>e", vim.diagnostic.open_float, "Show Diagnostic Error")
			end

			mason_lspconfig.setup({
				ensure_installed = { "pyright", "ruff", "lua_ls" },
				handlers = {
					function(server_name)
						local opts = {
							on_attach = on_attach,
							capabilities = capabilities,
						}

						if server_name == "pyright" then
							opts.settings = {
								python = {
									pythonPath = get_python_path(),
								}
							}
						end

						lspconfig[server_name].setup(opts)
					end,
				},
			})
		end,
	},
}
