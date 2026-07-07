return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.clang_format,
			},
		})

		-- Format C/C++ files on save using clang-format.
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("CppFormatOnSave", { clear = true }),
			pattern = { "*.cc", "*.cpp", "*.h", "*.hpp" },
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})

		vim.keymap.set("n", "<C-f>", vim.lsp.buf.format, {})
	end,
}
