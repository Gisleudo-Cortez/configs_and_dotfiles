return {
	-- Icons first (lazy load by other plugins)
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Status line
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function()
			local components = require("core.components")
			return {
				options = {
					theme = "catppuccin",
					component_separators = "|",
					section_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = { components.truncated_path }, -- <- custom component
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				extensions = { "nvim-tree", "quickfix", "mason" },
			}
		end,
	},

	-- Notifications
	{
		"rcarriga/nvim-notify",
		lazy = false,
		config = function()
			vim.notify = require("notify")
		end,
	},
}
