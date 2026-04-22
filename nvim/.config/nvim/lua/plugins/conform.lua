-- lua/plugins/conform.lua
return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = "ConformInfo",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format", "ruff_organize_imports" },
				go = { "gofmt", "goimports" },
				rust = { "rustfmt" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				sh = { "shfmt" },
			},
			format_on_save = {
				lsp_format = "fallback",
				timeout_ms = 1500,
			},
		},
		keys = {
			{
				"<leader>fm",
				function()
					require("conform").format({ async = true })
				end,
				desc = "Format code",
			},
		},
	},
}
