return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

        local jsaez_fugitive = vim.api.nvim_create_augroup("jsaez_fugitive", {})
        local autocmd = vim.api.nvim_create_autocmd

        autocmd("BufWinEnter", {
            group = jsaez_fugitive,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then return end

                local bufnr = vim.api.nvim_get_current_buf()
                local opts = { buffer = bufnr, remap = false }
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git("push")
                end, opts)
                vim.keymap.set("n", "<leader>P", function()
                    vim.cmd.Git({ "pull", "--rebase" })
                end, opts)
                -- NOTE: allows setting the branch and tracking when not configured correctly
                vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts)
            end,
        })

        vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
        vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
        vim.cmd("set diffopt+=vertical")
    end,
}
