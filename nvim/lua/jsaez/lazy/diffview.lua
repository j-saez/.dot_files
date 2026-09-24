-- snacks git_log sets item.commit as a plain string (the short hash).
local function get_hash(item)
    if type(item.commit) == "string" and item.commit ~= "" then
        return item.commit
    end
    if type(item.commit) == "table" then
        return item.commit.hash or ""
    end
    return item.hash or ""
end

-- Graph log picker: runs git log --all --graph so branching topology is visible.
-- Each commit line is tagged with SOH (\1) separators so the hash can be extracted
-- unambiguously even when graph-prefix characters (* | / \) precede it.
-- Tab to multi-select up to 2 commits, Enter to open diffview.
-- 1 commit  →  DiffviewOpen <hash>          (commit vs working tree)
-- 2 commits →  DiffviewOpen <older>..<newer> (between two commits)
local function git_compare_commits()
    local SEP = "\1"
    -- tformat fields: graph_prefix SEP full_hash SEP short_hash SEP decorations SEP subject SEP date SEP author
    local fmt = "tformat:" .. SEP .. "%H" .. SEP .. "%h" .. SEP .. "%D" .. SEP .. "%s" .. SEP .. "%cr" .. SEP .. "%an"

    Snacks.picker.pick({
        title = "Compare Commits — all branches  (Tab=select up to 2, Enter=diff)",
        preview = "git_show",
        finder = function(opts, ctx)
            local root = Snacks.git.get_root() or vim.fn.getcwd()
            return require("snacks.picker.source.proc").proc(
                ctx:opts({
                    cmd = "git",
                    cwd = root,
                    args = { "-c", "core.quotepath=false", "log", "--all", "--graph",
                             "--pretty=" .. fmt, "--abbrev-commit", "--color=never" },
                    transform = function(item)
                        if not item.text:find(SEP, 1, true) then
                            item.graph_only = true
                            return true
                        end
                        local parts = vim.split(item.text, SEP, { plain = true })
                        item.graph_prefix = parts[1] or ""
                        item.commit       = parts[3] or ""   -- short hash
                        item.decorations  = parts[4] or ""   -- HEAD -> main, origin/main …
                        item.msg          = parts[5] or ""
                        item.date         = parts[6] or ""
                        item.author       = parts[7] or ""
                        item.cwd          = root
                        return true
                    end,
                }),
                ctx
            )
        end,
        format = function(item, _)
            if item.graph_only then
                return { { item.text, "Comment" } }
            end
            local c = {}
            if item.graph_prefix ~= "" then
                c[#c + 1] = { item.graph_prefix .. " ", "Comment" }
            end
            if item.decorations ~= "" then
                c[#c + 1] = { "(" .. item.decorations .. ") ", "Special" }
            end
            c[#c + 1] = { item.commit .. " ", "Number" }
            c[#c + 1] = { item.msg .. " ", "Normal" }
            c[#c + 1] = { "(" .. item.date .. ") ", "Comment" }
            c[#c + 1] = { "<" .. item.author .. ">", "String" }
            return c
        end,
        confirm = function(picker)
            local items = picker:selected({ fallback = true })
            picker:close()
            local commits = vim.tbl_filter(function(i) return i.commit and i.commit ~= "" end, items)
            if #commits == 0 then return end
            local h1 = commits[1].commit
            if #commits == 1 then
                vim.cmd("DiffviewOpen " .. h1)
            else
                local h2 = commits[2].commit
                vim.cmd("DiffviewOpen " .. h2 .. ".." .. h1)
            end
        end,
    })
end

-- Show commits that touched the current file; select one to diff it against
-- the working copy using fugitive's vertical split.
local function git_file_compare()
    Snacks.picker.git_log_file({
        title = "File vs Commit  (Enter=diff current file)",
        confirm = function(picker)
            local items = picker:selected({ fallback = true })
            picker:close()
            if #items == 0 then return end
            local hash = get_hash(items[1])
            if hash == "" then return end
            vim.cmd("Gdiffsplit " .. hash)
        end,
    })
end

return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
        { "<leader>gd", "<cmd>DiffviewOpen<cr>",           desc = "Diffview open (vs HEAD)" },
        { "<leader>gD", "<cmd>DiffviewFileHistory %<cr>",  desc = "Diffview file history" },
        { "<leader>gx", "<cmd>DiffviewClose<cr>",          desc = "Diffview close" },
        { "<leader>gc", git_compare_commits,               desc = "Compare commits (picker)" },
        { "<leader>gf", git_file_compare,                  desc = "File vs commit (picker)" },
        { "<leader>g?", function() require("jsaez.git_help").open() end, desc = "Git keybindings help" },
        { "<leader>m?", function() require("jsaez.git_help").open("merge") end, desc = "Merge conflict commands" },
    },
    opts = {},
}
