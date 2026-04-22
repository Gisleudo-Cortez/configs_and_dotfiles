-- lua/plugins/lsp.lua
return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = { ui = { border = "rounded" } },
	},

	-- Ensures formatters/linters/tools are auto-installed (Mason alone does NOT do this)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"stylua",
				"ruff",
				"gofumpt",
				"goimports",
				"rustfmt",
				"prettierd",
				"shfmt",
				"debugpy",
				"js-debug-adapter",
			},
			auto_update = false,
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Robust Python path detection (venv-aware)
			local function get_python_path()
				local root = vim.fs.dirname(vim.fs.find({ ".git", "pyproject.toml", "setup.py" }, { upward = true })[1])
				if root then
					for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
						local p = vim.fs.joinpath(root, rel)
						if vim.fn.executable(p) == 1 then
							return p
						end
					end
				end
				return vim.fn.exepath("python3") or "python"
			end

			local function on_attach(client, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
				end
				map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				map("n", "gr", vim.lsp.buf.references, "References")
				map("n", "gI", vim.lsp.buf.implementation, "Implementation")
				map("n", "K", vim.lsp.buf.hover, "Hover Docs")
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
				map("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
				map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
				map("n", "<leader>de", vim.diagnostic.open_float, "Show Diagnostic")
			end

			-- ── QML filetype detection ───────────────────────────────────────────
			vim.filetype.add({ extension = { qml = "qml" } })

			-- ── Hyprland filetype detection ──────────────────────────────────────
			vim.filetype.add({
				pattern = {
					[".*hyprland%.conf"] = "hyprlang",
					[".*hyprlock%.conf"] = "hyprlang",
					[".*/hypr/.*%.conf"] = "hyprlang",
				},
			})

			mason_lspconfig.setup({
				ensure_installed = {
					"pyright",
					"ruff",
					"lua_ls",
					"gopls",
					"rust_analyzer",
					"ts_ls",
					"cssls",
					"html",
					"jsonls",
					"hyprls", -- Hyprland config LSP
				},
				handlers = {
					-- Default handler
					function(server_name)
						lspconfig[server_name].setup({
							on_attach = on_attach,
							capabilities = capabilities,
						})
					end,

					-- Pyright: venv-aware python path
					["pyright"] = function()
						lspconfig.pyright.setup({
							on_attach = on_attach,
							capabilities = capabilities,
							settings = {
								python = {
									pythonPath = get_python_path(),
									analysis = {
										autoSearchPaths = true,
										useLibraryCodeForTypes = true,
										diagnosticMode = "openFilesOnly",
									},
								},
							},
						})
					end,

					-- ruff: diagnostics only; conform owns formatting
					["ruff"] = function()
						lspconfig.ruff.setup({
							on_attach = function(client, bufnr)
								client.server_capabilities.documentFormattingProvider = false
								on_attach(client, bufnr)
							end,
							capabilities = capabilities,
						})
					end,

					-- lua_ls: Neovim runtime aware
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							on_attach = on_attach,
							capabilities = capabilities,
							settings = {
								Lua = {
									runtime = { version = "LuaJIT" },
									workspace = {
										checkThirdParty = false,
										library = vim.api.nvim_get_runtime_file("", true),
									},
									diagnostics = { globals = { "vim" } },
									telemetry = { enable = false },
								},
							},
						})
					end,

					-- gopls: module-aware
					["gopls"] = function()
						lspconfig.gopls.setup({
							on_attach = on_attach,
							capabilities = capabilities,
							settings = {
								gopls = {
									analyses = { unusedparams = true },
									staticcheck = true,
									gofumpt = false,
								},
							},
						})
					end,

					-- hyprls: installed via Mason, hyprlang filetype set above
					["hyprls"] = function()
						lspconfig.hyprls.setup({
							on_attach = on_attach,
							capabilities = capabilities,
							filetypes = { "hyprlang" },
						})
					end,
				},
			})

			-- ── QML LSP (not in Mason; resolved from PATH) ───────────────────────
			local qmlls_bin = (vim.fn.exepath("qmlls6") ~= "" and "qmlls6")
				or (vim.fn.exepath("qmlls") ~= "" and "qmlls")
				or nil

			if qmlls_bin then
				lspconfig.qmlls.setup({
					cmd = { qmlls_bin },
					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = { "qml" },
				})
			else
				vim.notify("qmlls not found — install Qt 6 and ensure qmlls/qmlls6 is on PATH", vim.log.levels.INFO)
			end
		end,
	},
}
