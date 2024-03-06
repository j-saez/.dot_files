return {
    "folke/zen-mode.nvim",
    config = function()
        vim.keymap.set("n", "<leader>zz", function()
            require("zen-mode").setup {
                window = {
                    height = vim.o.lines,
                    width = vim.o.columns,
                    options = {
                        signcolumn = "yes",
                        number = true,
                        relativenumber = true,
                    }
                },
            }
            require("zen-mode").toggle()
            vim.wo.wrap = false
            vim.wo.number = true
            vim.wo.rnu = true
            ColorMyPencils()
        end)
    end
}
