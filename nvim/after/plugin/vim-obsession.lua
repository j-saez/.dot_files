-- Get the name of the current working directory
local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

-- Define the session name based on the working directory
local session_name = cwd

-- Set 'sessionoptions' to control what is included in session files
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"

-- Define the session file path in the current working directory
local session_path = session_name .. ".vim"

-- Automatically create a session if it doesn't exist
if vim.fn.filereadable(session_path) == 0 then
    vim.cmd("Obsession " .. session_path)
end

-- Automatically load the session when Neovim starts
vim.cmd("source " .. session_path)
