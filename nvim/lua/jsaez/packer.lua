local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- this file can be laoded by acllin 'lua require('plugins')' from your ini.vim
--
-- Only requiered if you have packer configured as 'opt'
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(
	function()
		-- Packer can manage itself
		use 'wbthomason/packer.nvim'

		-- Color schemes
		use 'gruvbox-community/gruvbox'
        use 'folke/tokyonight.nvim'

		-- File explorers
		use { 'nvim-tree/nvim-tree.lua',
		    requires = {
			'nvim-tree/nvim-web-devicons', -- optional, for file icons
		    },
		    tag = 'nightly' -- optional, updated every week. (see issue #1193)
		}

		-- Telescope dependencies
		use 'nvim-lua/plenary.nvim'
		use 'nvim-telescope/telescope.nvim'
		use 'sharkdp/fd'
		use 'BurntSushi/ripgrep'

		-- LSP -- IDE
		use ('nvim-treesitter/nvim-treesitter', {['do'] = vim.fn[':TSUpdate']})
		use 'folke/lsp-colors.nvim' -- Automatically creates missing lsp diagnostics highlight grous for color schemes that dont yet suppor the Neovim 0.5 builtin lsp client Debugging (DAP) use 'mfussenegger/nvim-dap' use 'rcarriga/nvim-dap-ui' use 'theHamsta/nvim-dap-virtual-text' use 'nvim-telescope/telescope-dap.nvim'
		use({ "folke/trouble.nvim" })
        use {
          'VonHeikemen/lsp-zero.nvim',
          branch = 'v1.x',
          requires = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {'williamboman/mason.nvim'},           -- Optional
            {'williamboman/mason-lspconfig.nvim'}, -- Optional

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},         -- Required
            {'hrsh7th/cmp-nvim-lsp'},     -- Required
            {'hrsh7th/cmp-buffer'},       -- Optional
            {'hrsh7th/cmp-path'},         -- Optional
            {'saadparwaiz1/cmp_luasnip'}, -- Optional
            {'hrsh7th/cmp-nvim-lua'},     -- Optional
            {'hrsh7th/cmp-cmdline'},

            -- Snippets
            {'L3MON4D3/LuaSnip'},             -- Required
            {'rafamadriz/friendly-snippets'}, -- Optional
          }
        }

        -- DAP
        use 'mfussenegger/nvim-dap'
        use 'jay-babu/mason-nvim-dap.nvim'
        use 'rcarriga/nvim-dap-ui'
        use 'theHamsta/nvim-dap-virtual-text'
        use 'nvim-telescope/telescope.dap'

		-- Formaters and linters
		use 'jose-elias-alvarez/null-ls.nvim'

		-- Lualine
		use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt = true } }

		-- Zen mode
		use { "folke/zen-mode.nvim" }

	end)
