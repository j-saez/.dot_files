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
  -- Load completion and LSP capability helpers
  local cmp = require("cmp")
  local cmp_lsp = require("cmp_nvim_lsp")

  -- Combine LSP capabilities with nvim-cmp capabilities for autocompletion support
  local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
  )

  -- Set up fidget.nvim for LSP progress notifications
  require("fidget").setup({})

  -- Set up Mason (LSP/DAP/linter installer)
  require("mason").setup()

  -- Set up Mason LSPconfig to install and configure LSPs
  require("mason-lspconfig").setup({
    ensure_installed = {
      "lua_ls",
      "pyright",
      "ltex",
      "marksman",
      "dockerls",
      "clangd",
    },

    handlers = {
      -- Default handler for most servers
      function(server_name)
        require("lspconfig")[server_name].setup({
          capabilities = capabilities,
        })
      end,

      -- Custom setup for Lua language server
      ["lua_ls"] = function()
        require("lspconfig").lua_ls.setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" }, -- Prevent "undefined global 'vim'" warning
              },
            },
          },
        })
      end,
    }
  })

  -- Set diagnostic signs and display options (Neovim 0.10+)
  vim.diagnostic.config({
    signs = {
      priority=1,
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN]  = "",
        [vim.diagnostic.severity.INFO]  = "",
        [vim.diagnostic.severity.HINT]  = "",
      },
    },
    update_in_insert = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })

  -- Completion item selection behavior
  local cmp_select = { behaviour = cmp.SelectBehavior.Select }

  -- Set up nvim-cmp (completion plugin)
  cmp.setup({
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
      ["<C-m>"] = cmp.mapping.select_prev_item(cmp_select),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<CR>"]  = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),
    }),
    sources = cmp.config.sources(
      {
        { name = "nvim_lsp" },
        { name = "luasnip" },
      },
      {
        { name = "buffer" },
      }
    ),
  })
end

}
