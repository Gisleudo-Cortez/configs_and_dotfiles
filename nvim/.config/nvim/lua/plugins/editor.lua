-- lua/plugins/editor.lua

return {
	-- 1. Flash.nvim: Lightning fast motions
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"Sc",
				mode = { "n" },
				function()
					require("flash").remote()
				end,
				desc = "Flash Remote",
			},
		},
	},

	-- 2. Mini.surround: Efficiently manipulate quotes/brackets/tags
	{
		"echasnovski/mini.surround",
		version = "*",
		config = function()
			require("mini.surround").setup()
		end,
	},

	-- 3. Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = {
				"lua",
				"python",
				"rust",
				"javascript",
				"typescript",
				"go",
				"vim",
				"vimdoc",
				"regex",
				"bash",
				"qmljs", -- QML
				"hyprlang", -- Hyprland config
			},
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = "<cr>",
					node_decremental = "<bs>",
				},
			},
		},
		config = function(_, opts)
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				return
			end
			configs.setup(opts)
		end,
	},

	-- 4. Statusline & Tabline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					globalstatus = true,
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					disabled_filetypes = { statusline = {} },
				},
				sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { { "filename", path = 2, shorting_target = 40 } },
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "location" },
				},
				tabline = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {
						{
							"buffers",
							show_fileicons = true,
							show_filename_only = true,
							mode = 0,
							buffers_color = {
								active = { fg = "#FFFFFF", bg = "#007ACC" },
								inactive = { fg = "#6A737D", bg = "#F3F4F5" },
							},
						},
					},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
			})
		end,
	},

	-- 5. Mini.icons
	{
		"echasnovski/mini.icons",
		event = "VeryLazy",
		opts = {},
		config = function()
			require("mini.icons").setup({})
		end,
	},

	-- 6. nvim-autopairs: Treesitter-aware bracket/quote auto-closing
	--    Chosen over mini.pairs (no TS context, no cmp hook) and
	--    ultimate-autopair (more config, marginal gain).
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			local autopairs = require("nvim-autopairs")
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")

			autopairs.setup({
				-- Won't insert pairs inside strings or comments
				check_ts = true,
				ts_config = {
					lua = { "string" },
					python = { "string" },
					rust = { "string" },
				},
				-- <M-e> wraps the next expression in the chosen pair
				fast_wrap = { map = "<M-e>" },
				-- Prevents double-closing when a snippet already contains the closing char
				enable_check_bracket_line = false,
			})

			-- Inserts `()` after confirming a callable from cmp.
			-- Fires after LuaSnip expansion, so there is no conflict.
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
}
