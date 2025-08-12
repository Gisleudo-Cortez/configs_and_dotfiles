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
			wk.setup({})
			wk.register({
				b = { name = "Buffer" },
				f = { name = "Find" },
				t = { name = "Terminal" },
			}, {
				prefix  = "<leader>",
				mode    = "n",
				noremap = true,
				silent  = true,
			})
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
