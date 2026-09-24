return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	keys = {
		{ "<C-f>", function() require("conform").format({ lsp_format = "fallback" }) end, desc = "Format buffer" },
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "black" },
			c = { "clang_format" },
			cpp = { "clang_format" },
		},
		-- Only C/C++ are formatted on save; other filetypes use <C-f>.
		format_on_save = function(bufnr)
			local ft = vim.bo[bufnr].filetype
			if ft == "c" or ft == "cpp" then
				return { timeout_ms = 500, lsp_format = "never" }
			end
		end,
	},
}
