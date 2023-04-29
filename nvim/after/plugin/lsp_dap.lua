require("mason").setup()
require("mason-lspconfig").setup()

-- LSP 
local lsp = require("lsp-zero")
lsp.preset("recommended")
lsp.ensure_installed({
    'pyright',
    'clang',
})

lsp.on_attach(function(client, bufnr)
  print("pyright attached to this file.")
  local opts = {buffer = bufnr, remap = false}
  vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, {buffer=0}, opts)
  vim.keymap.set("n", "gw", function() vim.lsp.buf.document_symbol() end, {buffer=0}, opts)
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, {buffer=0}, opts)
  vim.keymap.set("n", "gt", function() vim.lsp.buf.type_definition() end, {buffer=0}, opts)
  vim.keymap.set("n", "<leader>af", function() vim.lsp.buf.code_action() end, {buffer=0}, opts)
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, {buffer=0}, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, {buffer=0}, opts)
end)
lsp.setup()

-- DAP
local dap = require("dap")
require("dapui").setup()
require("mason-nvim-dap").setup({
    ensure_installed = {"python", "cppdbg"},
    handlers = {},
})
require("dapui").setup()

vim.keymap.set("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>")
vim.keymap.set("n", "<F10>", "<cmd>lua require'dap'.step_over()<cr>")
vim.keymap.set("n", "<F11>", "<cmd>lua require'dap'.step_into()<cr>")
vim.keymap.set("n", "<F12>", "<cmd>lua require'dap'.step_out()<cr>")
vim.keymap.set("n", "<leader>b", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
