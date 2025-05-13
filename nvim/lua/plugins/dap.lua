-- Debugging (DAP and UI + adapters for Python, Go, JS)
return {
	{ "mfussenegger/nvim-dap" },
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap   = require("dap")
			local dapui = require("dapui")
			dapui.setup()
			dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
			dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
			dap.listeners.before.event_exited["dapui"]     = function() dapui.close() end

			-- DAP keybindings
			local map                                      = vim.keymap.set
			map("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			map("n", "<F6>", dap.terminate, { desc = "Debug: Stop" })
			map("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			map("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			map("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			map("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
		end,
	},
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			local mason_registry = srequire("mason-registry")
			if not mason_registry or not mason_registry.get_package then
				vim.notify("Mason registry is unavailable", vim.log.levels.ERROR)
				return
			end
			local pkg = mason_registry.get_package("debugpy")
			if not pkg or type(pkg.get_install_path) ~= "function" then
				vim.notify("Unable to find Mason package for debugpy", vim.log.levels.ERROR)
				return
			end
			if not pkg:is_installed() then
				vim.notify("Please install debugpy via :MasonInstall debugpy", vim.log.levels.WARN)
				return
			end
			local python_path = pkg:get_install_path() .. "/venv/bin/python"
			if vim.fn.executable(python_path) == 0 then
				local alt = pkg:get_install_path() .. "/debugpy/adapter"
				if vim.fn.executable(alt) == 1 then
					python_path = alt
				else
					vim.notify("No debugpy executable found", vim.log.levels.ERROR)
					return
				end
			end
			require("dap-python").setup(python_path)
		end,
	},
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		config = function()
			require("dap-go").setup()
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		ft = { "javascript", "typescript" },
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			local mason_registry = srequire("mason-registry")
			if not mason_registry then
				vim.notify("Mason registry not available", vim.log.levels.ERROR)
				return
			end
			local pkg = mason_registry.get_package("js-debug-adapter")
			if pkg and pkg:is_installed() then
				local dbg_path = pkg:get_install_path()
				require("dap-vscode-js").setup({
					debugger_path = dbg_path,
					adapters = { "pwa-node" },
				})
			else
				vim.notify("Please install 'js-debug-adapter' via Mason", vim.log.levels.WARN)
			end
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		opts = {},
	},
}
