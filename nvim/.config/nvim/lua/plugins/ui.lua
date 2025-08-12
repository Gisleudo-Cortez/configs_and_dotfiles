-- UI enhancements (statusline, bufferline, dashboard, notifications, icons)
return {
	-- Icons (for filetypes, etc., used by many plugins)
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Statusline (lualine)
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
					lualine_c = { components.truncated_path },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				extensions = { "nvim-tree", "quickfix", "mason" },
			}
		end,
	},

	-- Bufferline (show open buffers in the tabline)
	{
		"akinsho/bufferline.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				separator_style = "slant",
				show_buffer_close_icons = false,
				show_close_icon = false,
			},
		},
	},

	-- Dashboard (start screen)
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		config = function()
			local db = require("dashboard")

			-- ===== Header text =====
			local header = {
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝",
			}

			db.setup({
				theme = "hyper",
				config = {
					header = header,

					-- ===== Quick tools =====
					shortcut = {
						{ icon = " ", desc = "New File", group = "@string", action = "enew", key = "n" },
						{ icon = " ", desc = "Find File", group = "@string", action = "Telescope find_files", key = "f" },
						{ icon = "󰱼 ", desc = "Live Grep", group = "@string", action = "Telescope live_grep", key = "g" },
						{ icon = " ", desc = "Projects", group = "@string", action = "Telescope projects", key = "p" },
						{ icon = " ", desc = "File Explorer", group = "@string", action = "NvimTreeToggle", key = "e" },
						{ icon = " ", desc = "Manage Plugins", group = "@string", action = "Lazy", key = "l" },
						{ icon = " ", desc = "Edit Config", group = "@string", action = "Telescope find_files cwd=~/.config/nvim", key = "c" },
						{ icon = " ", desc = "Restore Session", group = "@string", action = "SessionManager load_session", key = "s" },
						{ icon = " ", desc = "Quit", group = "@string", action = "qa", key = "q" },
					},

					-- ===== Recent projects =====
					project = {
						enable = true,
						limit = 8,
						icon = " ",
						label = " Recent Projects",
						action = function(path)
							vim.cmd("cd " .. path)
							require("telescope.builtin").find_files({ cwd = path })
						end,
					},

					-- ===== Most recent files =====
					mru = {
						limit = 10,
						icon = " ",
						label = " Recent Files",
						cwd_only = false,
					},

					footer = { "⚡ Sharp tools make good work." },
				},
			})

			-- ===== Gradient painter =====
			local palette = {
				"#f5e0dc", "#f2cdcd", "#f5c2e7", "#cba6f7",
				"#b4befe", "#89b4fa", "#74c7ec", "#94e2d5",
				"#a6e3a1", "#f9e2af", "#f2cdcd",
			}

			local ns = vim.api.nvim_create_namespace("DashboardGradient")

			local function paint_gradient(buf, start_line, count)
				for i = 1, count do
					local color = palette[(i - 1) % #palette + 1]
					local hl = ("DashboardGrad%d"):format(i)
					vim.api.nvim_set_hl(0, hl, { fg = color })
					vim.api.nvim_buf_add_highlight(buf, ns, hl, start_line + i - 1, 0, -1)
				end
			end

			local function find_header_start(buf, hdr)
				local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local first = hdr[1]:gsub("^%s+", ""):gsub("%s+$", "")
				for i, l in ipairs(lines) do
					local s = l:gsub("^%s+", ""):gsub("%s+$", "")
					if s == first then
						return i - 1
					end
				end
				return nil
			end

			local function paint_now(buf)
				local start = find_header_start(buf, header)
				if start then
					paint_gradient(buf, start, #header)
				end
			end

			vim.api.nvim_create_autocmd("User", {
				pattern = "DashboardLoaded",
				callback = function(ev)
					vim.defer_fn(function() paint_now(ev.buf) end, 10)
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dashboard",
				callback = function(ev)
					vim.defer_fn(function() paint_now(ev.buf) end, 30)
				end,
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
	}

	,


	-- Notifications (nvim-notify)
	{
		"rcarriga/nvim-notify",
		lazy = false, -- load immediately to override vim.notify
		config = function() vim.notify = require("notify") end,
	},
}
