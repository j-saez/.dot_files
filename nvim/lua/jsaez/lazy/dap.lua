return {

    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "mfussenegger/nvim-dap-python",
    },

    config = function()
        local python_path = vim.fn.system("pyenv which python"):gsub("\n", "") or "/usr/bin/python"
        local dap = require("dap")
        local dapui = require("dapui")

        require("dap").set_log_level("DEBUG")

        -- Before every new session, delete any stale [dap-terminal] buffers so
        -- nvim-dap's internal pool never hands back a buffer with old content.
        -- Without this, a failed attach (e.g. ptrace denied) leaves a dirty buffer
        -- in the pool; the next attempt then hits "termopen requires unmodified buffer".
        local _orig_run = dap.run
        dap.run = function(config, opts)
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_get_name(buf):match('%[dap%-terminal%]') then
                    pcall(vim.api.nvim_buf_delete, buf, { force = true })
                end
            end
            return _orig_run(config, opts)
        end

        require("nvim-dap-virtual-text").setup()
        require("mason-nvim-dap").setup({
            ensure_installed = { "python", "cppdbg", "codelldb" },
            handlers = {
                function(config)
                    require('mason-nvim-dap').default_setup(config)
                end,

                -- mason-nvim-dap's default codelldb handler sets the executable
                -- path with a literal '~' which the OS cannot resolve. Override
                -- it here using vim.fn.stdpath so the path is always fully
                -- expanded before nvim-dap tries to run it.
                ["codelldb"] = function()
                    dap.adapters.codelldb = {
                        type = 'server',
                        port = '${port}',
                        executable = {
                            command = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/adapter/codelldb',
                            args = { '--port', '${port}' },
                        },
                    }
                end,
            },
        })
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
        dap.listeners.before.disconnect["dapui_config"] = function()
            dapui.close()
        end

        -- nvim-dap reuses terminal buffers via a pool. A reused buffer still has
        -- content from the previous session, so termopen() fails with "requires
        -- unmodified buffer". Deleting the buffer on session end forces the pool
        -- entry invalid; the next acquire then creates a fresh empty buffer.
        local function delete_term_buf(session)
            if session.term_buf and vim.api.nvim_buf_is_valid(session.term_buf) then
                pcall(vim.api.nvim_buf_delete, session.term_buf, { force = true })
            end
        end
        dap.listeners.after.event_terminated["fix_terminal_pool"] = delete_term_buf
        dap.listeners.after.event_exited["fix_terminal_pool"] = delete_term_buf
        dap.listeners.after.disconnect["fix_terminal_pool"] = delete_term_buf


        -- Mapping for the debuggin session
        vim.keymap.set("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>")
        vim.keymap.set("n", "<F10>", "<cmd>lua require'dap'.step_over()<cr>")
        vim.keymap.set("n", "<F11>", "<cmd>lua require'dap'.step_into()<cr>")
        vim.keymap.set("n", "<F12>", "<cmd>lua require'dap'.step_out()<cr>")
        vim.keymap.set("n", "<leader>b", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
        vim.keymap.set("n", "<leader>bl", function() Snacks.picker.dap_breakpoints() end, { desc = "Dap Breakpoints" })
        vim.keymap.set("n", "<leader>dq", function()
            dap.disconnect({ terminateDebuggee = false })
            dapui.close()
        end, { desc = "DAP Disconnect (detach)" })

        -- cpp configuration
        dap.adapters.cppdbg = {
          id = 'cppdbg',
          type = 'executable',
          command = vim.fn.stdpath('data') .. '/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
        }

        local function get_processes()
          local output = vim.fn.systemlist('ps -eo pid=,comm= --sort=comm 2>/dev/null')
          local procs = {}
          for _, line in ipairs(output) do
            local pid, name = line:match('^%s*(%d+)%s+(%S+)')
            if pid and name then
              table.insert(procs, { pid = tonumber(pid), name = name })
            end
          end
          return procs
        end

        local function get_tracer(pid)
          return vim.fn.system(
            'grep TracerPid /proc/' .. pid .. '/status 2>/dev/null | awk \'{print $2}\''
          ):gsub('%s+', '')
        end

        local function release_tracer(pid)
          local tracer = get_tracer(pid)
          if tracer == '' or tracer == '0' then return end
          -- SIGKILL: kernel releases ptrace immediately as part of process teardown
          vim.fn.system('kill -9 ' .. tracer .. ' 2>/dev/null')
          -- Poll until TracerPid clears (up to 2 s)
          for _ = 1, 20 do
            vim.fn.system('sleep 0.1')
            if get_tracer(pid) == '0' then break end
          end
        end

        -- Snacks-based attach: bypasses processId coroutine issues by calling dap.run directly
        -- Uses cppdbg (GDB) — better DWARF compatibility with GCC-compiled binaries
        vim.keymap.set('n', '<leader>da', function()
          vim.ui.select(get_processes(), {
            prompt = 'Attach to Process',
            format_item = function(p) return string.format('[%d] %s', p.pid, p.name) end,
          }, function(choice)
            if not choice then return end
            release_tracer(choice.pid)
            dap.run({
              name = 'Attach (cppdbg)',
              type = 'cppdbg',
              request = 'attach',
              processId = choice.pid,
              program = vim.fn.resolve('/proc/' .. choice.pid .. '/exe'),
              cwd = vim.fn.getcwd(),
              setupCommands = {
                { text = '-enable-pretty-printing', description = 'enable pretty printing', ignoreFailures = false },
              },
            })
          end)
        end, { desc = 'DAP Attach to process' })

        local last_exec = {}

        local function find_colcon_ws()
          local dir = vim.fn.getcwd()
          for _ = 1, 8 do
            if vim.fn.isdirectory(dir .. "/install") == 1 and
               vim.fn.isdirectory(dir .. "/build") == 1 and
               vim.fn.isdirectory(dir .. "/src") == 1 then
              return dir
            end
            local parent = vim.fn.fnamemodify(dir, ":h")
            if parent == dir then break end
            dir = parent
          end
          return vim.fn.getcwd()
        end

        local function pick_executable(default_dir)
          local key = vim.fn.getcwd()
          local default = last_exec[key] or (find_colcon_ws() .. default_dir)
          local path = vim.fn.input('Executable: ', default, 'file')
          if path == '' then return '' end
          last_exec[key] = path
          local info = vim.fn.system('file ' .. vim.fn.shellescape(path))
          if info:match('stripped') and not info:match('with debug_info') then
            vim.notify('WARNING: binary has no debug symbols — rebuild with --build-type Debug', vim.log.levels.WARN)
          end
          return path
        end

        local cpp_configs = {
          {
            name = "Launch file (cppdbg)",
            type = "cppdbg",
            request = "launch",
            program = function() return pick_executable('/') end,
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
          {
            name = "Launch file (codelldb)",
            type = "codelldb",
            request = "launch",
            program = function() return pick_executable('/') end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
          },
          {
            name = "Attach to process (codelldb)",
            type = "codelldb",
            request = "attach",
            processId = function()
              local filter = vim.fn.input('Process filter: ')
              if filter == '' then return nil end
              local lines = vim.fn.systemlist(
                'ps -eo pid=,comm= --sort=comm 2>/dev/null | grep -i '
                .. vim.fn.shellescape(filter) .. ' | grep -v grep'
              )
              if #lines == 0 then
                vim.notify('No process found matching: ' .. filter, vim.log.levels.WARN)
                return nil
              end
              if #lines == 1 then
                return tonumber(lines[1]:match('^%s*(%d+)'))
              end
              local choices = { 'Select process:' }
              local pids = {}
              for _, line in ipairs(lines) do
                local pid = tonumber(line:match('^%s*(%d+)'))
                if pid then
                  table.insert(choices, line)
                  table.insert(pids, pid)
                end
              end
              local idx = vim.fn.inputlist(choices)
              if idx < 1 or idx > #pids then return nil end
              return pids[idx]
            end,
            cwd = '${workspaceFolder}',
          },
          {
            -- ROS2: executable lives at install/<pkg>/lib/<pkg>/<exec> after colcon build
            name = "ROS2 Launch node (codelldb)",
            type = "codelldb",
            request = "launch",
            program = function() return pick_executable('/install/') end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            terminal = "integrated",
          },
        }

        dap.configurations.cpp = cpp_configs
        dap.configurations.c = cpp_configs
        dap.configurations.rust = cpp_configs
    end,
}
