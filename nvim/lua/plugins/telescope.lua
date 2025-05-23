-- Fuzzy finder (Telescope)
return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
			{ "<leader>fg", function() require("telescope.builtin").live_grep() end,  desc = "Live Grep" },
			{ "<leader>fb", function() require("telescope.builtin").buffers() end,    desc = "Find Buffers" },
		},
		opts = function()
			local actions = require("telescope.actions")
			return {
				defaults = {
					file_ignore_patterns = { "node_modules", ".git/", "target" },
					layout_strategy = "horizontal",
					layout_config = { prompt_position = "top", preview_width = 0.55 },
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<Esc>"] = actions.close,
						},
					},
				},
			}
		end,
	},
}

