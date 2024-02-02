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
                if vim.bo.ft ~= "fugitive" then
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local opts = {buffer = bufnr, remap = false}
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git('push')
                end, opts)

                -- rebase always
                vim.keymap.set("n", "<leader>P", function()
                    vim.cmd.Git({'pull',  '--rebase'})
                end, opts)

                -- NOTE: It allows me to easily set the branch i am pushing and any tracking
                -- needed if i did not set the branch up correctly
                vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts);
            end,
        })

        -- Map "gu" in normal mode to execute the command "diffget //2" in Neovim's diff mode.
        -- This command pulls changes from the second (remote) version of a conflicted section.
        vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")

        -- Map "gh" in normal mode to execute the command "diffget //3" in Neovim's diff mode.
        -- This command pulls changes from the third (local) version of a conflicted section.
        vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")


    end

}
