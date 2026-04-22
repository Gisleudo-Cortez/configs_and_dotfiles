-- lua/plugins/ui.lua

return {
	-- 1. Noice.nvim: High-end UI for command line, messages, and popups
	{
		"folke/noice.nvim",
		event        = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
		opts         = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					-- FIX: "vim.lsp.util.set_formatting" does not exist.
					-- The correct key is "stylize_markdown"; without it LSP hover
					-- docs are not rendered by Noice.
					["vim.lsp.util.stylize_markdown"]                = true,
					-- Also recommended: routes cmp docs through Noice
					["cmp.entry.get_documentation"]                  = true,
				},
			},
			presets = {
				bottom_search         = true,
				command_palette       = false,
				long_message_to_split = true,
				inc_rename            = false,
				lsp_doc_border        = true,
			},
			views = {
				cmdline_popup = {
					border = "rounded",
					size   = { width = 60, height = "auto" },
				},
				popupmenu = {
					relative = "editor",
					border   = "rounded",
					size     = { width = 50, height = 10 },
				},
			},
		},
	},

	-- 2. Dressing.nvim: Makes vim.ui.select and vim.ui.input look modern
	{
		"stevearc/dressing.nvim",
		opts = {},
	},

	-- 3. Nvim-Notify: Beautiful floating notifications
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			stages  = "fade",
		},
	},
}
