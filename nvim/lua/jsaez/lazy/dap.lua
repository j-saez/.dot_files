local default_handler = function(config)
    require('mason-nvim-dap').default_setup(config)
end

local python_handler = function(config)
    -- Read debug configuration from debug_configuration.json
    local debug_config = vim.fn.json_decode(vim.fn.readfile(".debug_configuration.json"))
    local python_config = debug_config.python or {}

    -- Set up Python debugger configuration

    local venv_path = require("os").getenv('VIRTUAL_ENV')
    local default_python_path = venv_path and ((vim.fn.has('win32') == 1 and venv_path .. '/Scripts/python') or venv_path .. '/bin/python') or nil

    -- visit https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for more info
    -- also visit: https://code.visualstudio.com/docs/python/debugging#_set-configuration-options
    config.adapters.python = {
        type = "executable",
        request = python_config.request or "launch",
        name = python_config.name or "Python Debug",
        program = python_config.program or "${file}",
        pythonPath = python_config.pythonPath or default_python_path,
        cwd = python_config.cwd or "${workspaceFolder}",
        args = python_config.args or {},
        env = python_config.env or {},
        debugOptions = python_config.debugOptions or {},
    }

    require('mason-nvim-dap').default_setup(config) -- don't forget this!
end

return{

    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-telescope/telescope-dap.nvim",
    },

    config = function()

        local dap = require("dap")
        local dapui = require("dapui")

        require("telescope").load_extension("dap")
        require("dapui").setup()
        require("nvim-dap-virtual-text").setup()
        require("mason-nvim-dap").setup({
            ensure_installed = {"python", "cppdbg"},
            handlers = {default_handler, python_handler}
        })

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
    end

}
