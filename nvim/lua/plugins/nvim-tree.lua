-- File explorer (nvim-tree)
return {
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeFocus" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
		},
		opts = {
			view = { width = 35 },
			renderer = {
				highlight_git = true,
				icons = { show = { folder_arrow = false } },
			},
			diagnostics = { enable = true },
			git = { enable = true },
		},
	},
}

