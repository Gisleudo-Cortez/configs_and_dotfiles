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
			highlight        = { enable = true },
			indent           = { enable = true },
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
	{
	},
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.setup({}) -- mantém sua configuração padrão
		-- Novo formato de registro de grupos
		wk.register({
			b = { name = "Buffer" }, -- agrupa <leader>b*
			f = { name = "Find" }, -- agrupa <leader>f*
			t = { name = "Terminal" }, -- agrupa <leader>t*
		}, {
			prefix  = "<leader>", -- prefixo comum
			mode    = "n", -- mapeamento em modo normal
			noremap = true, -- garante não-recursividade
			silent  = true, -- evita eco de comandos
		})
	end,
	{
		"akinsho/toggleterm.nvim",
		keys = {
			{ "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
		},
		opts = {
			size = 15,
			open_mapping = nil, -- disable built-in mapping (using our custom mapping)
			shade_terminals = true,
			direction = "horizontal",
		},
	},


}
