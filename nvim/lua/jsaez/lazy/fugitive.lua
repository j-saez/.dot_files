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

        -- Legend popup
        local legend_win = nil
        local legend_buf = nil

        local lines = {
            "  Staging               ",
            "  s       stage file    ",
            "  u       unstage file  ",
            "  U       unstage all   ",
            "  -       toggle stage  ",
            "  X       discard change",
            "                        ",
            "  Diff & Browse         ",
            "  =       inline diff   ",
            "  dd      diff horiz.   ",
            "  dv      diff vert.    ",
            "  ↵       open file     ",
            "  o       open in split ",
            "                        ",
            "  Commit                ",
            "  cc      commit        ",
            "  ca      amend commit  ",
            "  cw      reword msg    ",
            "                        ",
            "  Remote                ",
            "  <ldr>p  push          ",
            "  <ldr>P  pull --rebase ",
            "  <ldr>t  push -u origin",
            "                        ",
            "  g?      full help     ",
        }

        local width = 26

        local function get_buf()
            if legend_buf and vim.api.nvim_buf_is_valid(legend_buf) then
                return legend_buf
            end
            legend_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(legend_buf, 0, -1, false, lines)
            vim.bo[legend_buf].modifiable = false
            vim.bo[legend_buf].bufhidden = "hide"

            -- Highlight section headers
            local ns = vim.api.nvim_create_namespace("FugitiveLegend")
            for i, line in ipairs(lines) do
                if not line:match("^  %s") and line:match("%S") then
                    vim.api.nvim_buf_add_highlight(legend_buf, ns, "Title", i - 1, 0, -1)
                end
            end

            return legend_buf
        end

        local function show()
            if legend_win and vim.api.nvim_win_is_valid(legend_win) then return end
            local row = vim.o.lines - #lines - 3
            legend_win = vim.api.nvim_open_win(get_buf(), false, {
                relative = "editor",
                row = row,
                col = vim.o.columns - width - 3,
                width = width,
                height = #lines,
                style = "minimal",
                border = "rounded",
                focusable = false,
                zindex = 50,
            })
            vim.wo[legend_win].winblend = 15
        end

        local function hide()
            if legend_win and vim.api.nvim_win_is_valid(legend_win) then
                vim.api.nvim_win_close(legend_win, true)
            end
            legend_win = nil
        end

        local grp = vim.api.nvim_create_augroup("FugitiveLegend", { clear = true })
        autocmd("BufEnter", {
            group = grp,
            callback = function()
                if vim.bo.filetype == "fugitive" then show() end
            end,
        })
        autocmd({ "BufLeave", "WinLeave" }, {
            group = grp,
            callback = function()
                if vim.bo.filetype == "fugitive" then hide() end
            end,
        })
    end,
}
