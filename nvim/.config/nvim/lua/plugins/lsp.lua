-- LSP servers, installer, and per-language tweaks (robust to older pins)

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

	-- Bridge between Mason and lspconfig
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

	-- lspconfig proper
	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
		config = function()
			-- Uniform diagnostics UI
			vim.diagnostic.config({
				underline = true,
				virtual_text = { spacing = 2, prefix = "●" },
				signs = true,
				severity_sort = true,
			})

			local lspconfig       = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities    = require("cmp_nvim_lsp").default_capabilities()

			local on_attach       = function(client, bufnr)
				local bufmap = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
				bufmap("n", "K", vim.lsp.buf.hover, "Hover")
				bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
				bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				bufmap("n", "gr", vim.lsp.buf.references, "References")
				bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
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

			-- Common defaults for all servers
			local function base(opts)
				return vim.tbl_deep_extend("force", {
					on_attach = on_attach,
					capabilities = capabilities,
				}, opts or {})
			end

			-- Per-server overrides
			local overrides = {
				lua_ls = base({
					settings = { Lua = { diagnostics = { globals = { "vim" } } } },
				}),
				pyright = base({
					settings = { python = { pythonPath = get_python_path() } },
				}),
				ruff = base({
					init_options = { settings = { args = {} } },
				}),
			}

			mason_lspconfig.setup() -- safe for any version

			-- BEST option: feature-detect setup_handlers, else fall back.
			if type(mason_lspconfig.setup_handlers) == "function" then
				mason_lspconfig.setup_handlers({
					-- default handler
					function(server)
						lspconfig[server].setup(overrides[server] or base())
					end,
					-- explicit overrides
					["lua_ls"] = function() lspconfig.lua_ls.setup(overrides.lua_ls) end,
					["pyright"] = function() lspconfig.pyright.setup(overrides.pyright) end,
					["ruff"] = function() lspconfig.ruff.setup(overrides.ruff) end,
				})
			else
				-- Legacy path: iterate installed servers
				for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
					if lspconfig[server] then
						lspconfig[server].setup(overrides[server] or base())
					end
				end
				-- Ensure ruff gets configured even if not reported in some old versions
				if lspconfig.ruff and not lspconfig.ruff.manager then
					lspconfig.ruff.setup(overrides.ruff)
				end
			end
		end,
	},
}
