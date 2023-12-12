vim.g.netrw_winsize = 15 -- Change the size of the Netrw window when it creates a split to 30%
vim.g.netrw_list_hide = '\\(\\^\\|\\s\\s\\)\\zs\\.\\S\\+' -- Hide dotfiles on load
vim.g.netrw_localcopydircmd = 'cp -r' -- Change the copy command to enable recursive copy of directories
vim.cmd('hi! link netrwMarkFile Search') -- Highlight marked files in the same way search matches are

-- Remaps for opening the file browser
vim.keymap.set("n", "<leader>e", "<cmd>Lexplore %:p:h<cr>") -- current file
vim.keymap.set("n", "<leader>ew", "<cmd>Lexplore<cr>") -- working directory

vim.g.newtrw_remove_recursive = function()
  if vim.bo.filetype == 'netrw' then
    -- Define the command-line mapping
    vim.api.nvim_buf_set_keymap(0, 'c', '<CR>', 'rm -r<CR>', { noremap = true, silent = true })

    -- Store the current cursor position and the current file in marks 'u' and 'f'
    vim.api.nvim_command('normal mu')
    vim.api.nvim_command('normal mf')

    -- Try executing the command 'mx', catch errors and display a message if canceled
    local ok, result = pcall(vim.api.nvim_command, 'normal mx')
    if not ok then
      print("Canceled")
    end

    -- Unmap the command-line mapping
    vim.api.nvim_buf_del_keymap(0, 'c', '<CR>')
  end
end

-- Remaps for when using it
local function newtrwMappings()
  vim.api.nvim_buf_set_keymap(0, 'n', 'b', 'u', { noremap = true, silent = true }) -- go back in history
  vim.api.nvim_buf_set_keymap(0, 'n', 'u', '-^', { noremap = true, silent = true }) -- go up a directory
  vim.api.nvim_buf_set_keymap(0, 'n', 'dd', '<cmd>lua vim.g.newtrw_remove_recursive()<cr>', { noremap = true, silent = true }) -- Remove a directory recursively
end

-- Create an autocommand group and set up the autocommand for the 'netrw' filetype
vim.api.nvim_create_augroup("netrw_mapping", {clear=true})
vim.api.nvim_create_autocmd('filetype', {
        pattern='netrw',
        callback=newtrwMappings,
        group='netrw_mapping'
    }
)
