print("\t\t.config/jsaez/mappings/general_remaps.lua")
local Remap = require('jsaez.mappings.get_noremap_vars')

local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap
local nmap = Remap.nmap

-- Opening the file explorer 
nnoremap('<leader>e', ':NvimTreeOpen <cr>') 
nnoremap('<leader>qq', ':NvimTreeClose <cr>') 

-- Keeping the curson centered when searching with n, N and joining lines with J
nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')
nnoremap('J', 'mzJ`z')

-- Undo break points (check what does this)
-- When uncommented i am not able to write . and , symbols
--inoremap(',', '<c-g>u')
--inoremap('.', '<c-g>u')

-- Moving text
vnoremap('J', ':m \'>+1<CR>gv=gv')
vnoremap('K', ':m \'<-2<CR>gv=gv')
inoremap('<c-j>', '<esc>:m .+1<CR>==')
inoremap('<c-k>', '<esc>:m .-2<CR>==')
inoremap('<leader>k', ':m .-2<CR>==')
inoremap('<leader>j', ':m .-2<CR>==')

-- allows repaste yanked text
vnoremap('p', '"_dp')

-- Run macros over different lines
local keymap = vim.api.nvim_set_keymap
keymap([[x]], [[@]], [[:<C-u>lua ExecuteMacroOverVisualRange()<CR>]], {noremap=true})

function ExecuteMacroOverVisualRange()
	vim.api.nvim_exec([[
		echo "@".getcmdline()
		execute ":'<,'>normal @".nr2char(getchar())
	]], [[true]])
end

-- Keep visual selection after indenting
vim.api.nvim_exec([[
	vmap > >gv
	vmap < <gv
]], [[true]])

-- Buffers
nnoremap('<leader>bd', '<cmd>bd<cr>') -- Delete buffer
nnoremap('<leader>bn', '<cmd>bn<cr>') -- Go to next buffer
nnoremap('<leader>bp', '<cmd>bp<cr>') -- Go to previous buffer

-- Switch between splits
nnoremap('<C-h>', '<C-w>h')
nnoremap('<C-j>', '<C-w>j')
nnoremap('<C-k>', '<C-w>k')
nnoremap('<C-l>', '<C-w>l')

-- Resize between splits
nnoremap('<C-A-L>', '<cmd> :vertical resize +3 <CR>')
nnoremap('<C-A-H>', '<cmd> :vertical resize -3 <CR>')
nnoremap('<C-A-J>', '<cmd> :resize +3 <CR>')
nnoremap('<c-A-K>', '<cmd> :resize -3 <CR>')

