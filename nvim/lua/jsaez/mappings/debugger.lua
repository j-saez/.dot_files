-- Remaps for the debugger
vim.keymap.set("n", "<F5>", "<cmd> lua require'dap'.continue() <cr>")
vim.keymap.set("n", "<F10>", "<cmd> lua require'dap'.step_over() <cr>")
vim.keymap.set("n", "<F11>", "<cmd> lua require'dap'.step_into() <cr>")
vim.keymap.set("n", "<F12>", "<cmd> lua require'dap'.step_out() <cr>")
vim.keymap.set("n", "<leader>b", "<cmd> lua require'dap'.toggle_breakpoint() <cr>")
vim.keymap.set("n", "<leader>B", "<cmd> lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition ')) <cr>")
vim.keymap.set("n", "<leader>lp", "<cmd> lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log...')) <cr>")
vim.keymap.set("n", "<leader>dr", "<cmd> lua require'dap'.repl.open() <cr>")

-- TODO: Install debugger for python and try.
-- If we do not do that, the dap is not going to work
