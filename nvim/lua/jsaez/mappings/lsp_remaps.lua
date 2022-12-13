-- LSP remaps

local Remap = require('jsaez.mappings.get_noremap_vars')

local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap
local nmap = Remap.nmap

custom_attach = function()
  print("pyright attached to this file.")
  --vim.lsp.buf.add_workspace_folder(vim.fn.getcwd())
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {buffer=0})
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer=0})
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {buffer=0})
  vim.keymap.set("n", "gw", vim.lsp.buf.document_symbol, {buffer=0})
  vim.keymap.set("n", "gr", vim.lsp.buf.references, {buffer=0})
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, {buffer=0})
  vim.keymap.set("n", "<leader>af", vim.lsp.buf.code_action, {buffer=0})
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {buffer=0})
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer=0})
end
--nnoremap('gd', ':lua vim.lsp.buf.definition()<cr>')
--nnoremap('gD', ':lua vim.lsp.buf.declaration()<cr>')
--nnoremap('gi', ':lua vim.lsp.buf.implementation()<cr>')
--nnoremap('gw', ':lua vim.lsp.buf.document_symbol()<cr>')
--nnoremap('gw', ':lua vim.lsp.buf.workspace_symbol()<cr>')
--nnoremap('gr', ':lua vim.lsp.buf.references()<cr>')
--nnoremap('gt', ':lua vim.lsp.buf.type_definition()<cr>')
--nnoremap('K', ':lua vim.lsp.buf.hover()<cr>')
--nnoremap('<c-k>', ':lua vim.lsp.buf.signature_help()<cr>')
--nnoremap('<leader>af', ':lua vim.lsp.buf.code_action()<cr>')
--nnoremap('<leader>rn', ':lua vim.lsp.buf.rename()<cr>')

require("nvim-lsp-installer").setup{}
require'lspconfig'.pyright.setup{
    on_attach = custom_attach,
    root_dir = vim.lsp.buf.add_workspace_folder(vim.fn.getcwd()),
}
