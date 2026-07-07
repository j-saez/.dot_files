local function apply_transparency()
    local groups = {
        "Normal", "NormalFloat", "NormalNC",
        "SignColumn", "NvimTreeNormal", "NvimTreeNormalNC",
        "WinSeparator", "VertSplit",
        "StatusLine", "StatusLineNC",
        "TabLine", "TabLineFill",
    }
    for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
    vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { reverse = true })
end

function ColorMyPencils(color)
    color = color or "tokyonight"
    vim.cmd.colorscheme(color)
    apply_transparency()
end

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = apply_transparency,
})

return {
    {
        "folke/tokyonight.nvim",
        name = "tokyonight",
        opts = {
            transparent = true,
            styles = {
                sidebars = "transparent",
                floats = "transparent",
            },
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            ColorMyPencils()
        end,
    }
}
