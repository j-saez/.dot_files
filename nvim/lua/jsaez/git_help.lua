-- Filterable git keybindings help (snacks picker).
-- Type to filter by section, key or description. Enter runs global keys;
-- keys that only exist inside a fugitive/diffview buffer just close the list.
local M = {}

-- { section, key, description, global? }
local keys = {
    { "fugitive", "<ldr>gs",   "git status window",              true },
    { "fugitive status", "s / u",     "stage / unstage file" },
    { "fugitive status", "U",         "unstage all" },
    { "fugitive status", "-",         "toggle stage" },
    { "fugitive status", "X",         "discard change" },
    { "fugitive status", "=",         "inline diff" },
    { "fugitive status", "dv / dd",   "diff vert / horiz" },
    { "fugitive status", "↵ / o",     "open file / in split" },
    { "fugitive status", "cc / ca",   "commit / amend" },
    { "fugitive status", "cw",        "reword commit message" },
    { "fugitive status", "<ldr>p",    "push" },
    { "fugitive status", "<ldr>P",    "pull --rebase" },
    { "fugitive status", "<ldr>t",    "push -u origin <branch>" },
    { "fugitive status", "g?",        "full fugitive help" },
    { "fugitive merge", "gu / gh",    "diffget ours (//2) / theirs (//3)" },

    { "gitsigns", "]h / [h",   "next / prev hunk" },
    { "gitsigns", "<ldr>ga",   "stage hunk",                     true },
    { "gitsigns", "<ldr>gu",   "undo stage hunk",                true },
    { "gitsigns", "<ldr>gp",   "preview hunk",                   true },
    { "gitsigns", "<ldr>gw",   "blame line",                     true },
    { "gitsigns", "<ldr>gi",   "diff vs index",                  true },
    { "gitsigns", "<ldr>gh",   "diff vs HEAD~1",                 true },

    { "diffview", "<ldr>gd",   "open (repo vs HEAD)",            true },
    { "diffview", "<ldr>gD",   "file history",                   true },
    { "diffview", "<ldr>gx",   "close",                          true },
    { "diffview", "<ldr>gc",   "compare commits (Tab=select, Enter=diff)", true },
    { "diffview", "<ldr>gf",   "file vs commit",                 true },
    { "diffview panel", "- / s",     "stage / unstage file" },
    { "diffview panel", "S / U",     "stage all / unstage all" },

    { "snacks", "<ldr>gl",     "git log",                        true },
    { "snacks", "<ldr>gL",     "git log (current file)",         true },
    { "snacks", "<ldr>gb",     "git branches",                   true },
    { "snacks", "<ldr>gS",     "git status picker (Tab=stage)",  true },

    { "merge", "]x / [x",      "next / prev conflict" },
    { "merge", "<ldr>co",      "choose ours" },
    { "merge", "<ldr>ct",      "choose theirs" },
    { "merge", "<ldr>cb",      "choose base" },
    { "merge", "<ldr>ca",      "choose all" },
    { "merge", "<ldr>cO",      "ours (whole file)" },
    { "merge", "<ldr>cT",      "theirs (whole file)" },
    { "merge", "<ldr>cB",      "base (whole file)" },
    { "merge", "<ldr>cA",      "all (whole file)" },
    { "merge", "dx / dX",      "delete conflict / all" },
    { "merge", "2do / 3do",    "get ours / theirs" },
}

function M.open(filter)
    local items = {}
    for _, k in ipairs(keys) do
        table.insert(items, {
            text = k[1] .. " " .. k[2] .. " " .. k[3],
            section = k[1], key = k[2], desc = k[3], global = k[4],
        })
    end

    Snacks.picker.pick({
        title = "Git keybindings",
        items = items,
        pattern = filter,
        layout = { preset = "select" },
        format = function(item)
            return {
                { string.format("%-16s", item.section), "Comment" },
                { string.format("%-10s", item.key), "Special" },
                { item.desc },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if item and item.global then
                local lhs = item.key:gsub("<ldr>", vim.g.mapleader or "\\")
                vim.api.nvim_feedkeys(vim.keycode(lhs), "m", false)
            end
        end,
    })
end

return M
