return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.black, -- Use black with pyproject.toml
			},
--			on_attach = function(client, bufnr)
--				if client.supports_method("textDocument/formatting") then
--					vim.api.nvim_create_autocmd("BufWritePre", {
--						group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
--						buffer = bufnr,
--						callback = function()
--							vim.lsp.buf.format({ async = true })
--						end,
--					})
--				end
--			end,
		})

		vim.keymap.set("n", "<C-f>", vim.lsp.buf.format, {})
	end,
}
