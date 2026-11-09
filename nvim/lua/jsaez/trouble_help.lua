-- Filterable Trouble keybindings help (snacks picker), same style as git_help.
-- Enter runs global keys; keys that only exist inside the Trouble window just close the list.
local M = {}

-- { section, key, description, global? }
local keys = {
    { "open", "<ldr>xw", "diagnostics (workspace)",                 true },
    { "open", "<ldr>xb", "diagnostics (current buffer)",            true },
    { "open", "<ldr>xs", "symbols in file",                         true },
    { "open", "<ldr>xr", "LSP defs/refs/impls (right panel)",       true },
    { "open", "<ldr>xl", "location list",                           true },
    { "open", "<ldr>xq", "quickfix list",                           true },

    { "trouble window", "<cr>",        "jump to item" },
    { "trouble window", "o",           "jump and close Trouble" },
    { "trouble window", "<c-s> / <c-v>", "jump in split / vsplit" },
    { "trouble window", "} / {",       "next / prev item (also ]] / [[)" },
    { "trouble window", "p",           "preview item" },
    { "trouble window", "P",           "toggle auto-preview" },
    { "trouble window", "s",           "cycle severity filter" },
    { "trouble window", "gb",          "toggle current-buffer filter" },
    { "trouble window", "i",           "inspect item" },
    { "trouble window", "dd",          "delete item from list" },
    { "trouble window", "r / R",       "refresh / toggle auto-refresh" },
    { "trouble window", "q / <esc>",   "close / cancel" },
    { "trouble window", "?",           "Trouble's built-in help" },

    { "folds", "za / zA",   "toggle fold / recursive" },
    { "folds", "zo / zc",   "open / close fold" },
    { "folds", "zR / zM",   "open all / close all" },
    { "folds", "zr / zm",   "reduce / more folding" },
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
        title = "Trouble keybindings",
        items = items,
        pattern = filter,
        layout = { preset = "select" },
        sort = { fields = { "idx" } },
        format = function(item)
            return {
                { string.format("%-16s", item.section), "Comment" },
                { string.format("%-15s", item.key), "Special" },
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
