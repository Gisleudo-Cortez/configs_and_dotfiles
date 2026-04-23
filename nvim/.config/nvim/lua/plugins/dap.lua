-- ============================================================================
-- lua/plugins/dap.lua
-- ----------------------------------------------------------------------------
-- nvim-dap = Debug Adapter Protocol client.  Paired with:
--   nvim-dap-ui              — floating panels (scopes, stacks, watches)
--   nvim-dap-virtual-text    — inline variable values
--   nvim-dap-python          — zero-config launch for pytest / current file
--   nvim-dap-go              — zero-config launch for delve
--
-- Adapter binaries (debugpy, delve, codelldb, js-debug-adapter) are installed
-- by mason-tool-installer in plugins/lsp.lua — no separate mason-nvim-dap
-- bridge required.  Keeps the dependency graph simple.
-- ============================================================================
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      { "mfussenegger/nvim-dap-python", ft = "python" },
      { "leoluz/nvim-dap-go",            ft = "go", opts = {} },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,          desc = "Continue"         },
      { "<leader>di", function() require("dap").step_into() end,         desc = "Step into"        },
      { "<leader>do", function() require("dap").step_over() end,         desc = "Step over"        },
      { "<leader>dO", function() require("dap").step_out() end,          desc = "Step out"         },
      { "<leader>dr", function() require("dap").repl.toggle() end,       desc = "Toggle REPL"      },
      { "<leader>dl", function() require("dap").run_last() end,          desc = "Run last"         },
      { "<leader>dt", function() require("dap").terminate() end,         desc = "Terminate"        },
      { "<leader>du", function() require("dapui").toggle() end,          desc = "Toggle DAP UI"    },
      { "<leader>dK", function() require("dap.ui.widgets").hover() end,  desc = "Hover var",       mode = { "n", "v" } },
      -- F-key aliases (old-config muscle memory)
      { "<F5>",  function() require("dap").continue() end,              desc = "Debug: Continue"   },
      { "<F6>",  function() require("dap").terminate() end,             desc = "Debug: Stop"       },
      { "<F9>",  function() require("dap").toggle_breakpoint() end,     desc = "Debug: Toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end,             desc = "Debug: Step over"  },
      { "<F11>", function() require("dap").step_into() end,             desc = "Debug: Step into"  },
      { "<F12>", function() require("dap").step_out() end,              desc = "Debug: Step out"   },
      -- Python-specific
      { "<leader>dPt", function() require("dap-python").test_method() end,  desc = "Debug test method",  ft = "python" },
      { "<leader>dPc", function() require("dap-python").test_class() end,   desc = "Debug test class",   ft = "python" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup({ commented = true })

      dap.listeners.before.attach.dapui_config           = function() dapui.open() end
      dap.listeners.before.launch.dapui_config           = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end

      local signs = {
        DapBreakpoint          = { text = "●", texthl = "DiagnosticError" },
        DapBreakpointCondition = { text = "◆", texthl = "DiagnosticWarn"  },
        DapLogPoint            = { text = "◆", texthl = "DiagnosticInfo"  },
        DapStopped             = { text = "→", texthl = "DiagnosticOk"    },
        DapBreakpointRejected  = { text = "●", texthl = "DiagnosticHint"  },
      }
      for name, s in pairs(signs) do
        vim.fn.sign_define(name, { text = s.text, texthl = s.texthl, linehl = "", numhl = "" })
      end

      -- ── Python (debugpy) ────────────────────────────────────────────
      local mason_debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      if vim.fn.filereadable(mason_debugpy) == 1 then
        require("dap-python").setup(mason_debugpy)
      else
        local sys_py = vim.fn.exepath("python3")
        if sys_py ~= "" then require("dap-python").setup(sys_py) end
      end

      -- ── JS / TS (js-debug-adapter) ──────────────────────────────────
      local mason_js = vim.fn.stdpath("data") ..
                       "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
      if vim.fn.filereadable(mason_js) == 1 then
        dap.adapters["pwa-node"] = {
          type = "server", host = "localhost", port = "${port}",
          executable = { command = "node", args = { mason_js, "${port}" } },
        }
        for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
          dap.configurations[ft] = dap.configurations[ft] or {}
          table.insert(dap.configurations[ft], {
            type = "pwa-node", request = "launch", name = "Launch file",
            program = "${file}", cwd = "${workspaceFolder}",
          })
        end
      end

      -- ── C / C++ / Rust (codelldb) ───────────────────────────────────
      local mason_codelldb = vim.fn.stdpath("data") ..
                             "/mason/packages/codelldb/extension/adapter/codelldb"
      if vim.fn.executable(mason_codelldb) == 1 then
        dap.adapters.codelldb = {
          type = "server", port = "${port}",
          executable = { command = mason_codelldb, args = { "--port", "${port}" } },
        }
        for _, ft in ipairs({ "c", "cpp", "rust" }) do
          dap.configurations[ft] = dap.configurations[ft] or {}
          table.insert(dap.configurations[ft], {
            name = "Launch (codelldb)", type = "codelldb", request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}", stopOnEntry = false,
          })
        end
      end
    end,
  },
}
