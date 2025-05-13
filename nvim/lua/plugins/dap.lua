return {
	{ "mfussenegger/nvim-dap" },
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap, dapui = require("dap"), require("dapui")
			dapui.setup()
			dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
			dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
			dap.listeners.before.event_exited["dapui"]     = function() dapui.close() end

			-- Keymaps
			local map                                      = vim.keymap.set
			map("n", "<F5>", dap.continue, { desc = "Continue" })
			map("n", "<F6>", dap.terminate, { desc = "Terminate" })
			map("n", "<F9>", dap.toggle_breakpoint, { desc = "Breakpoint" })
			map("n", "<F10>", dap.step_over, { desc = "Step over" })
			map("n", "<F11>", dap.step_into, { desc = "Step into" })
			map("n", "<F12>", dap.step_out, { desc = "Step out" })
		end,
	},
	-- Language‑specific helpers ------------------------------------------------
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = { "mason.nvim" },
		config = function()
			local mason_registry = srequire("mason-registry")
			if not mason_registry or not mason_registry.get_package then
				vim.notify("Mason registry is unavailable or broken", vim.log.levels.ERROR)
				return
			end

			local pkg = mason_registry.get_package("debugpy")
			if not pkg or type(pkg.get_install_path) ~= "function" then
				vim.notify("Invalid debugpy package from mason-registry", vim.log.levels.ERROR)
				return
			end

			if not pkg:is_installed() then
				vim.notify("debugpy is not installed. Please install via :MasonInstall debugpy",
					vim.log.levels.WARN)
				return
			end

			local python_executable = pkg:get_install_path() .. "/venv/bin/python"
			if vim.fn.executable(python_executable) == 0 then
				local alt = pkg:get_install_path() .. "/debugpy/adapter"
				if vim.fn.executable(alt) == 1 then
					python_executable = alt
				else
					vim.notify("Could not find a valid debugpy executable at: " .. python_executable,
						vim.log.levels.ERROR)
					return
				end
			end

			require("dap-python").setup(python_executable)
			vim.notify("nvim-dap-python setup with debugpy at: " .. python_executable, vim.log.levels.INFO)
		end
	},
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		config = function()
			require("dap-go").setup()
		end
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		ft = { "javascript", "typescript" },
		dependencies = { "mason.nvim" },
		config = function()
			local mason_registry = srequire("mason-registry")
			if not mason_registry then
				vim.notify("Mason registry is unavailable", vim.log.levels.ERROR)
				return
			end

			local pkg = mason_registry.get_package("js-debug-adapter")
			if pkg and pkg:is_installed() then
				local path = pkg:get_install_path()
				require("dap-vscode-js").setup({ debugger_path = path, adapters = { "pwa-node" } })
			else
				vim.notify("js-debug-adapter not found or not installed via Mason.", vim.log.levels.WARN)
			end
		end
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		opts = {}
	},
}
