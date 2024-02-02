require('jsaez.settings')
require('jsaez.lazy_init')
require('jsaez.remap')

local augroup = vim.api.nvim_create_augroup
local jsaez_group = augroup('jsaez', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

-- Highlight yanked text for 40 s
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

-- Delete extra spaced at the end of lines before saving the file
autocmd({"BufWritePre"}, {
    group = jsaez_group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

local function attach(opts)
end

autocmd('LspAttach', {
    group = jsaez_group,
    callback = function(e)
        --print("LSP attached to this file.")

        local opts = {buffer = e.buf, remap = false}
        vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, {buffer=0}, opts)
        vim.keymap.set("n", "gw", function() vim.lsp.buf.document_symbol() end, {buffer=0}, opts)
        vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, {buffer=0}, opts)
        vim.keymap.set("n", "gt", function() vim.lsp.buf.type_definition() end, {buffer=0}, opts)
        vim.keymap.set("n", "<leader>af", function() vim.lsp.buf.code_action() end, {buffer=0}, opts)
        vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, {buffer=0}, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, {buffer=0}, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, {buffer=0}, opts)

    end
})

