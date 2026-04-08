-- lua/plugins/conform.lua (Updated)
return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" }, -- Load on save
		cmd = "ConformInfo",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black", "isort" },
				go = { "gofmt", "goimports" },
				rust = { "rustfmt" },
				javascript = { "prettierd", "prettier" },
				typescript = { "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				yaml = { "prettierd", "prettier" },
				html = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				sh = { "shfmt" },
			},
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 1000, -- Increased slightly for heavier formatters like black/prettier
			},
		},
		keys = {
			{ "<leader>fm", function() require("conform").format({ async = true }) end, desc = "Format code" },
		},
	},
}
