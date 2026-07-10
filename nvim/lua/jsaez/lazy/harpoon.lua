return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        vim.keymap.set("n", "<leader>hm", function() harpoon:list():add() end, { desc = "Harpoon mark file" })
        vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })

        vim.keymap.set("n", "<leader>ha", function() harpoon:list():select(1) end, { desc = "Harpoon file a" })
        vim.keymap.set("n", "<leader>hs", function() harpoon:list():select(2) end, { desc = "Harpoon file b" })
        vim.keymap.set("n", "<leader>hd", function() harpoon:list():select(3) end, { desc = "Harpoon file c" })
        vim.keymap.set("n", "<leader>hf", function() harpoon:list():select(4) end, { desc = "Harpoon file d" })

        vim.keymap.set("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Harpoon prev" })
        vim.keymap.set("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Harpoon next" })

        -- Legend popup, bottom-right of screen (matches fugitive/nvim-tree legend style)
        local legend_win = nil
        local legend_buf = nil

        local lines = {
            "  Harpoon                ",
            "  <ldr>hm  mark file     ",
            "  <ldr>hh  toggle menu   ",
            "                         ",
            "  Jump                   ",
            "  <ldr>ha  file a        ",
            "  <ldr>hs  file b        ",
            "  <ldr>hd  file c        ",
            "  <ldr>hf  file d        ",
            "  <ldr>hp  prev          ",
            "  <ldr>hn  next          ",
            "                         ",
            "  In menu                ",
            "  ↵        open          ",
            "  dd       remove entry  ",
            "  q / <Esc> close        ",
        }

        local width = 27

        local function get_buf()
            if legend_buf and vim.api.nvim_buf_is_valid(legend_buf) then
                return legend_buf
            end
            legend_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(legend_buf, 0, -1, false, lines)
            vim.bo[legend_buf].modifiable = false
            vim.bo[legend_buf].bufhidden = "hide"

            local ns = vim.api.nvim_create_namespace("HarpoonLegend")
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

        -- Harpoon sets the buffer filetype to "harpoon" only after opening and
        -- entering its window, so BufEnter fires too early to see it; FileType
        -- fires exactly when the option is set, right after the window opens.
        local grp = vim.api.nvim_create_augroup("HarpoonLegend", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = grp,
            pattern = "harpoon",
            callback = show,
        })
        vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
            group = grp,
            callback = function()
                if vim.bo.filetype == "harpoon" then hide() end
            end,
        })
    end
}
