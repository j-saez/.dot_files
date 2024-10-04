return{

    "williamboman/mason-lspconfig.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "neovim/nvim-lspconfig",

        -- Autocommpletion
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-cmdline",

        -- Snippets
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',

        -- Lsp notifications
        "j-hui/fidget.nvim"
    },

    config = function()

        local cmp = require("cmp")
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilites = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "pyright",
                "ltex",
                "marksman",
                "dockerls",
                "clangd",
                "prettier",
            },

            handlers = {
                function(server_name)
                    require("lspconfig")[server_name].setup({
                        capabilites = capabilites,
                    })
                    -- print(server_name .. ' set up.')
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup({
                        capabilites = capabilites,
                        settings = {
                            Lua = {
                                diagnostics = { globals = {"vim"} }
                            }
                        }
                    })
                end
            }
        })

        local cmp_select = {behaviour = cmp.SelectBehavior.Select}

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end
            },

            mapping = cmp.mapping.preset.insert({
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-m>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<CR>'] = cmp.mapping.confirm({select = true}),
                ['<C-Space>'] = cmp.mapping.complete(),
            }),

            sources = cmp.config.sources(
                {
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },  -- For luasnip users.
                },
                {
                    { name = 'buffer' },
                }
            ),

            vim.diagnostic.config({
                update_in_insert = true,
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            }),
        })

    end

}
