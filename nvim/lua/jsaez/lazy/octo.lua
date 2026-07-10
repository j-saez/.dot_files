return {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
        "sindrets/diffview.nvim",
    },
    build = function() require("gitlab.server").build(true) end,
    opts = {},
    keys = {
        { "<leader>op", function() require("gitlab").choose_merge_request() end, desc = "Pick MR" },
        { "<leader>oo", function() require("gitlab").review() end,               desc = "MR review" },
        { "<leader>os", function() require("gitlab").summary() end,              desc = "MR summary" },
        { "<leader>oA", function() require("gitlab").approve() end,              desc = "MR approve" },
        { "<leader>or", function() require("gitlab").revoke() end,               desc = "MR revoke approval" },
        { "<leader>oc", function() require("gitlab").create_comment() end,       desc = "MR create comment" },
        { "<leader>on", function() require("gitlab").create_note() end,          desc = "MR create note" },
        { "<leader>om", function() require("gitlab").merge() end,                desc = "MR merge" },
        { "<leader>ob", function() require("gitlab").copy_mr_url() end,           desc = "MR copy URL to clipboard" },
        { "<leader>oP", function() require("gitlab").pipeline() end,             desc = "MR pipeline status" },
        { "<leader>od", function() require("gitlab").toggle_discussions() end,  desc = "MR toggle discussions" },
    },
}
