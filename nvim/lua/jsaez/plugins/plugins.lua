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

		-- File explorers
        --use { "nvim-telescope/telescope-file-browser.nvim" }
		use { 'kyazdani42/nvim-tree.lua',
		    requires = {
			'kyazdani42/nvim-web-devicons', -- optional, for file icons
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
		use 'neovim/nvim-lspconfig' -- requires to install lsp servers manually
		use 'williamboman/nvim-lsp-installer' -- To install lsp servers automatically

		-- Auto close
		use 'cohama/lexima.vim'

		-- Autocompletion
		use 'hrsh7th/cmp-nvim-lsp'
		use 'hrsh7th/cmp-buffer'
		use 'hrsh7th/cmp-path'
		use 'hrsh7th/cmp-cmdline'
		use 'hrsh7th/nvim-cmp'

        -- Snippets
        use 'L3MON4D3/LuaSnip' --snippet engine
	    use 'rafamadriz/friendly-snippets' -- a bunch of snippets to use

        -- Lualine
        use {
            'nvim-lualine/lualine.nvim',
            requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }

		-- Show indentation levels
		use 'Yggdroot/indentLine'
        
		-- Debugging (DAP)
		use 'mfussenegger/nvim-dap'
		use 'rcarriga/nvim-dap-ui'
		use 'theHamsta/nvim-dap-virtual-text'
		use 'nvim-telescope/telescope-dap.nvim'

	end)

