return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sharkdp/fd",
		"BurntSushi/ripgrep",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
		},
	},

	config = function()
		require("telescope").setup({
			extensions = {
				fzf = {},
			},
		})

		require("telescope").load_extension("fzf")

		local find_word = function()
			local word = vim.fn.expand("<cword>")
			require("telescope.builtin").grep_string({ search = word })
		end

		local find_WORD = function()
			local word = vim.fn.expand("<cWORD>")
			require("telescope.builtin").grep_string({ search = word })
		end

		vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
		vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
		vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
		vim.keymap.set("n", "<space>fg", require("jsaez.lazy.telescope.multi-ripgrep"))
		vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
		vim.keymap.set("n", "<leader>fw", find_word)
		vim.keymap.set("n", "<leader>fW", find_WORD)
	end,
}
