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
    end
}
