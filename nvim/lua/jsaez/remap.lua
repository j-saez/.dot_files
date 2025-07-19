-- Keeping the curson centered when searching with n, N and joining lines with J
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Move selected lines up or down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Substitutions
vim.keymap.set("x", "<leader>s",
  [[:s/\<<C-r><C-w>\>//g<Left><Left>]],
  { desc = "Substitute word under cursor in visual selection (case-sensitive, no confirmation)" })
vim.keymap.set("n", "<leader>s",
  [[:%s/\<<C-r><C-w>\>//g<Left><Left>]],
  { desc = "Substitute word under cursor globally (case-sensitive and NO confirmation)" })
vim.keymap.set("n", "<leader>sc",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gc<Left><Left><Left>]],
  { desc = "Substitute word under cursor globally (case-sensitive and with confirmation)" })

-- allows repaste yanked text
vim.keymap.set("v", "p", [["_dP]])

-- Run macros over different lines
vim.api.nvim_set_keymap([[x]], [[@]], [[:<C-u>lua ExecuteMacroOverVisualRange()<CR>]], {noremap=true})

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
vim.keymap.set("n","<leader>bd", "<cmd>bd<cr>") -- Delete buffer
vim.keymap.set("n","<leader>bn", "<cmd>bn<cr>") -- Go to next buffer
vim.keymap.set("n","<leader>bp", "<cmd>bp<cr>") -- Go to previous buffer

-- Switch between splits
vim.keymap.set("n","<C-h>", "<C-w>h")
vim.keymap.set("n","<C-j>", "<C-w>j")
vim.keymap.set("n","<C-k>", "<C-w>k")
vim.keymap.set("n","<C-l>", "<C-w>l")

-- Resize between splits
vim.keymap.set("n","<C-A-L>", "<cmd> vertical resize -3 <CR>")
vim.keymap.set("n","<C-A-H>", "<cmd> vertical resize +3 <CR>")
vim.keymap.set("n","<C-A-J>", "<cmd> resize +2 <CR>")
vim.keymap.set("n","<C-A-K>", "<cmd> resize -3 <CR>")

-- File explorer
vim.keymap.set("n", "<leader>e", "<cmd>Explore %:p:h<cr>") -- current file
vim.keymap.set("n", "<leader>ew", "<cmd>Explore<cr>") -- working directory
