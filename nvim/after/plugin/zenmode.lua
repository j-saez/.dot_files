-- Zenmode remaps
vim.keymap.set("n", "<leader>zz", function()
    require("zen-mode").setup {
        window = {
            width = 1.0,
            options = { }
        },
        plugins = {
            options = {
                enabled=false
            }
        }
    }
    require("zen-mode").toggle()
    vim.wo.wrap = false
    vim.wo.number = true
    vim.wo.rnu = true
    vim.opt.colorcolumn = "80"
    ColorMyPencils()
end)
