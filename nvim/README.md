# Nvim configuration

There are two main folders: lua and after.

Inside **lua** there is another folder called **jsaez**, which allocates inside the following files:
	
	1. init.lua: File to collect all the configuration inside jsaez folder.
	2. packer.lua: File where all the plugins that we want to have are installed.
	3. remap.lua: File that contains general remaps, but not the ones for the plugins.
	3. settings.lua: File that contains settings we desire for our vim experience.

Inside **after** there is another folder called **plugin**, which allocates inside the following files:

	1. colors.lua: File containing the information regarding the colorschemes for vim.
	2. lsp_dap.lua: File containing the setup and keymaps for lsp and dap.
	3. lualine.lua: File that contains the configuration for the status line.
	4. nvim-tree.lua: File that contains the configuration and keymaps for the file tree.
	5. telescope.lua: File that contains the configuration and keymaps for telescope fuzzy finder.
	6. treesitter.lua: File that contains the configuration and keymaps for treesitter
	7. trouble.lua: File that contains the configuration and keymaps for trouble (to inform about lsp error and warnings)
	8. zenmode.lua: File that contains the configuration and keymaps for zenmode.
