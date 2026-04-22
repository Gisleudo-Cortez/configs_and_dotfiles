-- lua/plugins/nvim-tree.lua

return {
	{
		"nvim-tree/nvim-tree.lua",
		cmd          = { "NvimTreeToggle", "NvimTreeFocus" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys         = {
			{ "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
		},
		opts         = {
			view        = { width = 35 },
			renderer    = {
				highlight_git = true,
				icons = { show = { folder_arrow = false } },
			},
			diagnostics = { enable = true },
			git         = { enable = true },
			-- FIX: filters was placed at the plugin-spec level (a sibling of opts),
			-- so Lazy.nvim never forwarded it to nvim-tree. Moved inside opts.
			filters     = {
				dotfiles = false,
			},
		},
	},
}
