----------
-- Sets --
----------

	-- There are 3 types of configuration options
	--
	--		Global options (vim.o)
	--		Local to window (vim.wo)
	--		Local to buffer (vim.bo)

	vim.wo.foldmethod = "manual"      -- set the code folding method
	vim.opt.termguicolors = true      -- set term gui colors (most terminals support this)
	vim.opt.backup = false            -- creates a backup file
	vim.opt.clipboard = "unnamedplus" -- allows newovim to acces the system clipboard
	vim.opt.cmdheight = 2             -- more space in the neovim command line for displaying messages
	vim.opt.conceallevel = 0          -- so that `` is visible in markdown files
	vim.opt.fileencoding = "uft-8"    -- the encoding wirtten to a file
	vim.opt.hlsearch = false          -- highlight all matches on previous search pattern
	vim.opt.ignorecase = true         -- ignore case in search patterns
	vim.opt.mouse = "a"               -- allow the mouse to be used in neovim
	vim.opt.pumheight = 10            -- pop up menu height
	vim.opt.showmode = true           -- we do not nee to see thing like -- INSER -- anymore
	vim.opt.smartcase = true          -- smart case
	vim.opt.smartindent = true        -- make indenting smarte again
	vim.opt.swapfile = false          -- creates a swapfile
	vim.opt.timeoutlen = 250          -- time to wait for a mapped sequence to complete (in ms)
	vim.opt.undofile = true           -- enable persistent undo
	vim.opt.updatetime = 300          -- faster completion (4000 ms default)
	vim.opt.writebackup = false       -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
	vim.opt.expandtab = true          -- convert tabs to spaces
	vim.opt.cursorline = false        -- highlight the current line
	vim.opt.number = true             -- set numbered lines
	vim.opt.relativenumber = true     -- set relative numbered lines
	vim.opt.numberwidth = 4           -- the number column width to  2 {default 4}
	vim.opt.wrap = false              -- display lines as one long line
	vim.opt.scrolloff = 10            -- is of my fav
	vim.opt.sidescrolloff = 10
	vim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
	vim.opt.tabstop = 4               -- insert 2 spaces for a tab
	vim.opt.softtabstop = 4
	vim.opt.shiftwidth = 4            -- the number of spaces inserted for each indentation
	vim.opt.splitbelow = true         -- force all horizontal splits to go below current window
	vim.opt.splitright = true         -- force all verical splits to go to the right of current window
	vim.opt.relativenumber=true
	vim.opt.nu=true                   -- get current line number
	vim.opt.wrap=false
	vim.opt.colorcolumn="80"
	vim.opt.signcolumn = "yes"        -- always show the sign column, otherwise it would shift the text each time
	vim.opt.incsearch=true

	-- Buffers
	vim.opt.hidden=true

	-- Leader key
	vim.g.mapleader= ";"

    -- Automatically configure Python 3 provider for Neovim
    local python3_path = vim.fn.system('pyenv which python3')
    vim.g.python3_host_prog = python3_path
