return {

    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-telescope/telescope-dap.nvim",
        "mfussenegger/nvim-dap-python",
    },

    config = function()
        local python_path = vim.fn.system("pyenv which python"):gsub("\n", "") or "/usr/bin/python"
        local dap = require("dap")
        local dapui = require("dapui")

        require("nvim-dap-virtual-text").setup()
        require("telescope").load_extension("dap")
        require("mason-nvim-dap").setup({ ensure_installed = { "python", "cppdbg" } })
        require("dap-python").setup(python_path)
        dapui.setup()

        -- Start the debugger UI automatically when the debuggin session is started
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end


        -- Mapping for the debuggin session
        vim.keymap.set("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>")
        vim.keymap.set("n", "<F10>", "<cmd>lua require'dap'.step_over()<cr>")
        vim.keymap.set("n", "<F11>", "<cmd>lua require'dap'.step_into()<cr>")
        vim.keymap.set("n", "<F12>", "<cmd>lua require'dap'.step_out()<cr>")
        vim.keymap.set("n", "<leader>b", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
        vim.keymap.set("n", "<leader>bl", "<cmd>lua require'telescope'.extensions.dap.list_breakpoints()<cr>")

        -- cpp configuration
        dap.adapters.cppdbg = {
          id = 'cppdbg',
          type = 'executable',
          command = vim.fn.stdpath('data') .. '/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
        }
        dap.configurations.cpp = {
          {
            name = "Launch file",
            type = "cppdbg",
            request = "launch",
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            setupCommands = {
              {
                text = '-enable-pretty-printing',
                description =  'enable pretty printing',
                ignoreFailures = false
              },
            },
          },
        }
    end,
}
