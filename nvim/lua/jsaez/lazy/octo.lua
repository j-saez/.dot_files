return {
    "pwntester/octo.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    keys = {
        { "<leader>op", "<cmd>Octo pr list<cr>",        desc = "PR list" },
        { "<leader>oo", "<cmd>Octo pr view<cr>",        desc = "PR view (current branch)" },
        { "<leader>oc", "<cmd>Octo pr checkout<cr>",    desc = "PR checkout" },
        { "<leader>om", "<cmd>Octo pr merge<cr>",       desc = "PR merge" },
        { "<leader>oi", "<cmd>Octo issue list<cr>",     desc = "Issue list" },
        { "<leader>or", "<cmd>Octo review start<cr>",   desc = "Start review" },
        { "<leader>oR", "<cmd>Octo review submit<cr>",  desc = "Submit review" },
    },
    opts = {
        picker = "snacks",
    },
}
