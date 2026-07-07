local function get_hash(item)
    return (item.commit and item.commit.hash) or item.hash or ""
end

-- Compare any 1 or 2 commits from git log.
-- Tab to multi-select (up to 2), Enter to open diffview.
-- 1 commit  →  DiffviewOpen <hash>          (commit vs working tree)
-- 2 commits →  DiffviewOpen <older>..<newer> (between two commits)
local function git_compare_commits()
    Snacks.picker.git_log({
        title = "Compare Commits  (Tab=select up to 2, Enter=diff)",
        confirm = function(picker)
            local items = picker:selected({ fallback = true })
            picker:close()
            if #items == 0 then return end
            local h1 = get_hash(items[1])
            if #items == 1 then
                vim.cmd("DiffviewOpen " .. h1)
            else
                -- items are newest-first; items[2] is the older commit
                local h2 = get_hash(items[2])
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
    "  <ldr>g?    toggle this help      ",
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
    },
    opts = {},
}
