return {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("treesitter-context").setup({
            max_lines = 5,       -- max lines of context shown at top
            min_window_height = 20,
            multiline_threshold = 1, -- collapse multi-line contexts to 1 line
            trim_scope = "outer",
        })

        vim.keymap.set("n", "[C", function()
            require("treesitter-context").go_to_context(vim.v.count1)
        end, { desc = "Jump to context" })
    end,
}
