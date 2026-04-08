-- lua/plugins/editor.lua
return {
	-- 1. Flash.nvim: Lightning fast motions
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "s",  mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
			{ "S",  mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "Sc", mode = { "n" },           function() require("flash").ascent() end,     desc = "Flash Ascent" },
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


	-- 3. Treesitter (Optimized for lazy.nvim)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = { "lua", "python", "rust", "javascript", "typescript", "go", "vim", "vimdoc", "regex", "bash" },
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
			-- We wrap the require in a pcall (protected call) to prevent
			-- crashing if the plugin is still being initialized.
			local status_ok, configs = pcall(require, "nvim-treesitter.configs")
			if not status_ok then
				return
			end
			configs.setup(opts)
		end,
	},



	-- 4. Statusline & Tabline (Final - Shows Open Tabs)
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- For file icons
		},
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
					-- Bottom statusline shows current file with relative path
					lualine_c = { { 'filename', path = 2, shorting_target = 40 } },
					lualine_x = {},
					lualine_y = {},
					lualine_z = { 'location' },
				},
				-- Top tabline shows all open tabs/buffers

				tabline = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {
						{
							'buffers',
							show_fileicons = true, -- Show file icons in tabs
							show_filename_only = true, -- Show full path (or set to true for just filename)
							mode = 'tabs', -- Alternative: 'tabs' for numbered tabs
							buffers_colors = {
								active = { fg = '#FFFFFF', bg = '#007ACC' },
								inactive = { fg = '#6A737D', bg = '#F3F4F5' }
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




}
