-- General editor enhancements (Treesitter, Git signs, autopairs, etc.)
return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = {
				"bash", "c", "css", "html", "javascript", "json", "lua", "python",
				"rust", "go", "typescript", "vim", "yaml", "sql", "markdown", "java",
			},
			highlight = { enable = true },
			indent = { enable = true },
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {}, -- use default settings
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- use default settings
	},

	-- which-key (FIXED: proper spec)
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({}) -- keep defaults

			-- New list-style spec (recommended by which-key)
			wk.add({
				{ "<leader>b",  group = "Buffer",        remap = false },
				{ "<leader>f",  group = "Find",          remap = false },
				{ "<leader>t",  group = "Terminal",      remap = false },
				-- (Optional) add labels for your existing mappings so the popup looks nicer:
				{ "<leader>w",  desc = "Save file" },
				{ "<leader>wq", desc = "Save & quit" },
				{ "<leader>bd", desc = "Delete buffer" },
				{ "<leader>ff", desc = "Find Files" },
				{ "<leader>fg", desc = "Live Grep" },
				{ "<leader>fb", desc = "Find Buffers" },
				{ "<leader>tt", desc = "Toggle terminal" },
			}, { mode = "n" })
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		keys = {
			{ "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
		},
		opts = {
			size = 15,
			open_mapping = nil,
			shade_terminals = true,
			direction = "horizontal",
		},
	},
}
