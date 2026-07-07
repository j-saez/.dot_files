return {
	"L3MON4D3/LuaSnip",
	-- follow latest release.
	version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- install jsregexp (optional!).
	build = "make install_jsregexp",
    dependencies = {"rafamadriz/friendly-snippets"},

    config = function()
        local ls = require("luasnip")
        local s = ls.snippet
        local t = ls.text_node
        local i = ls.insert_node
        local f = ls.function_node

        require("luasnip.loaders.from_vscode").lazy_load({ include = { "python", "cpp", "c" } })

        -- C++ snippets
        ls.add_snippets("cpp", {
            -- Header Guard
            s("hguard", {
                t("#ifndef "), f(function() return string.upper(vim.fn.expand("%:t:r") .. "_H") end), t({"", "#define "}), f(function() return string.upper(vim.fn.expand("%:t:r") .. "_H") end), t({"", "", ""}),
                i(0),
                t({"", "", "#endif // "}), f(function() return string.upper(vim.fn.expand("%:t:r") .. "_H") end),
            }),
            -- Class boilerplate
            s("class", {
                t("class "), i(1, "ClassName"), t({" {", "public:", "    "}),
                i(2, "ClassName"), t("();"),
                t({"", "    ~"}), i(3, "ClassName"), t("();"),
                t({"", "", "private:", "    "}), i(0),
                t({"", "};"}),
            }),
            -- Namespace block
            s("ns", {
                t("namespace "), i(1, "ns_name"), t({" {", "", "    "}),
                i(0),
                t({"", "", "} // namespace "}), i(2, "ns_name"),
            }),
        })
    end,
}
