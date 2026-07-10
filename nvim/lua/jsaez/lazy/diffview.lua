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

-- Git keybindings cheatsheet popup (toggle).
-- Matches the style of the fugitive legend in fugitive.lua.
local cheatsheet_win = nil
local cheatsheet_buf = nil

local cheatsheet_lines = {
    "  Fugitive                         ",
    "  <ldr>gs    git status            ",
    "  dv / dd    diff vert / horiz     ",
    "  cc / ca    commit / amend        ",
    "  <ldr>p     push                  ",
    "  <ldr>P     pull --rebase         ",
    "                                   ",
    "  Gitsigns — Hunks                 ",
    "  ]h / [h    next / prev hunk      ",
    "  <ldr>hs    stage hunk            ",
    "  <ldr>hu    undo stage hunk       ",
    "  <ldr>hp    preview hunk          ",
    "                                   ",
    "  Gitsigns — Diff & Blame          ",
    "  <ldr>hd    diff vs index         ",
    "  <ldr>hD    diff vs HEAD~1        ",
    "  <ldr>hb    blame line            ",
    "                                   ",
    "  Diffview                         ",
    "  <ldr>gd    open (repo vs HEAD)   ",
    "  <ldr>gD    file history          ",
    "  <ldr>gx    close                 ",
    "                                   ",
    "  Compare Picker                   ",
    "  <ldr>gC    compare commits       ",
    "             (Tab=select, Enter=diff)",
    "  <ldr>gF    file vs commit        ",
    "                                   ",
    "  Snacks Git                       ",
    "  <ldr>gl    git log               ",
    "  <ldr>gL    git log (file)        ",
    "  <ldr>gb    git branches          ",
    "  <ldr>gS    git status picker     ",
    "                                   ",
    "  Merge Tool                       ",
    "  ]x / [x    next/prev conflict    ",
    "  <ldr>co    choose ours           ",
    "  <ldr>ct    choose theirs         ",
    "  <ldr>cb    choose base           ",
    "  <ldr>ca    choose all            ",
    "  <ldr>cO    ours (whole file)     ",
    "  <ldr>cT    theirs (whole file)   ",
    "  <ldr>cB    base (whole file)     ",
    "  <ldr>cA    all (whole file)      ",
    "  dx / dX    del conflict / all    ",
    "  2do / 3do  get ours / theirs     ",
    "                                   ",
    "  <ldr>g?    toggle this help      ",
    "  <ldr>m?    merge commands popup  ",
}

local cheatsheet_width = 37

local function get_cheatsheet_buf()
    if cheatsheet_buf and vim.api.nvim_buf_is_valid(cheatsheet_buf) then
        return cheatsheet_buf
    end
    cheatsheet_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(cheatsheet_buf, 0, -1, false, cheatsheet_lines)
    vim.bo[cheatsheet_buf].modifiable = false
    vim.bo[cheatsheet_buf].bufhidden = "hide"

    local ns = vim.api.nvim_create_namespace("GitCheatsheet")
    for i, line in ipairs(cheatsheet_lines) do
        -- Section headers: non-empty lines that don't start with spaces+letter pairs (i.e. not key lines)
        if line:match("^  %u") and not line:match("^  [<%)%[]") then
            vim.api.nvim_buf_add_highlight(cheatsheet_buf, ns, "Title", i - 1, 0, -1)
        end
    end
    return cheatsheet_buf
end

local function toggle_cheatsheet()
    if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
        vim.api.nvim_win_close(cheatsheet_win, true)
        cheatsheet_win = nil
        return
    end
    local height = #cheatsheet_lines
    local row = math.max(0, vim.o.lines - height - 3)
    local col = math.max(0, vim.o.columns - cheatsheet_width - 3)
    cheatsheet_win = vim.api.nvim_open_win(get_cheatsheet_buf(), false, {
        relative  = "editor",
        row       = row,
        col       = col,
        width     = cheatsheet_width,
        height    = height,
        style     = "minimal",
        border    = "rounded",
        focusable = false,
        zindex    = 50,
        title     = " Git Help ",
        title_pos = "center",
    })
    vim.wo[cheatsheet_win].winblend = 15
end

-- Merge conflict legend popup (toggle with <leader>m?).
-- Centered on screen to distinguish it from the general git cheatsheet.
local merge_legend_win = nil
local merge_legend_buf = nil

local merge_legend_lines = {
    "  Merge Tool                       ",
    "  (diffview during git merge)      ",
    "                                   ",
    "  Navigation                       ",
    "  ]x / [x   next / prev conflict   ",
    "                                   ",
    "  Per-conflict                     ",
    "  <ldr>co   choose ours            ",
    "  <ldr>ct   choose theirs          ",
    "  <ldr>cb   choose base            ",
    "  <ldr>ca   choose all             ",
    "                                   ",
    "  Whole file                       ",
    "  <ldr>cO   ours                   ",
    "  <ldr>cT   theirs                 ",
    "  <ldr>cB   base                   ",
    "  <ldr>cA   all                    ",
    "                                   ",
    "  Misc                             ",
    "  dx / dX   del / del all          ",
    "  2do / 3do get ours / theirs      ",
    "                                   ",
    "  <ldr>m?   toggle this popup      ",
}

local merge_legend_width = 37

local function get_merge_legend_buf()
    if merge_legend_buf and vim.api.nvim_buf_is_valid(merge_legend_buf) then
        return merge_legend_buf
    end
    merge_legend_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(merge_legend_buf, 0, -1, false, merge_legend_lines)
    vim.bo[merge_legend_buf].modifiable = false
    vim.bo[merge_legend_buf].bufhidden = "hide"
    local ns = vim.api.nvim_create_namespace("MergeLegend")
    for i, line in ipairs(merge_legend_lines) do
        if line:match("^  %u") and not line:match("^  [<%)%[]") then
            vim.api.nvim_buf_add_highlight(merge_legend_buf, ns, "Title", i - 1, 0, -1)
        end
    end
    return merge_legend_buf
end

local function toggle_merge_legend()
    if merge_legend_win and vim.api.nvim_win_is_valid(merge_legend_win) then
        vim.api.nvim_win_close(merge_legend_win, true)
        merge_legend_win = nil
        return
    end
    local height = #merge_legend_lines
    merge_legend_win = vim.api.nvim_open_win(get_merge_legend_buf(), false, {
        relative  = "editor",
        row       = math.max(0, math.floor((vim.o.lines - height) / 2) - 2),
        col       = math.max(0, math.floor((vim.o.columns - merge_legend_width) / 2)),
        width     = merge_legend_width,
        height    = height,
        style     = "minimal",
        border    = "rounded",
        focusable = false,
        zindex    = 51,
        title     = " Merge Help ",
        title_pos = "center",
    })
    vim.wo[merge_legend_win].winblend = 15
end

return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
        { "<leader>gd", "<cmd>DiffviewOpen<cr>",           desc = "Diffview open (vs HEAD)" },
        { "<leader>gD", "<cmd>DiffviewFileHistory %<cr>",  desc = "Diffview file history" },
        { "<leader>gx", "<cmd>DiffviewClose<cr>",          desc = "Diffview close" },
        { "<leader>gC", git_compare_commits,               desc = "Compare commits (picker)" },
        { "<leader>gF", git_file_compare,                  desc = "File vs commit (picker)" },
        { "<leader>g?", toggle_cheatsheet,                 desc = "Git keybindings help" },
        { "<leader>m?", toggle_merge_legend,               desc = "Merge conflict commands" },
    },
    opts = {},
}
