-- lua/plugins/ui.lua
return {
	-- 1. Noice.nvim: High-end UI for command line, messages, and popups
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			-- Configure how messages and cmdline look
			lsp = {
				-- override LSP hover with noice
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.set_formatting"] = true,
				},
			},
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline in the middle
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = true, -- add a border to LSP docs
			},
		},
	},

	-- 2. Dressing.nvim: Makes vim.ui.select and vim.ui.input look modern
	{
		"stevearc/dressing.nvim",
		opts = {}, -- use default settings
	},

	-- 3. Nvim-Notify: Beautiful floating notifications
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			stages = "fade",
		},
	},

	-- 4. Lualine (Optional check): If you don't have a statusline yet, this is the standard.
	-- I will include a basic config here if it's missing from your other files.
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "auto", -- or match your theme (e.g., 'catppuccin')
				component_separators = "|",
				section_separators = "",
			},
		},
	},
}
