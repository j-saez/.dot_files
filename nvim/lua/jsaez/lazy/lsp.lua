return{

    "williamboman/mason-lspconfig.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "neovim/nvim-lspconfig",

        -- Autocompletion
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-cmdline",

    },

config = function()
  local cmp = require("cmp")
  local cmp_lsp = require("cmp_nvim_lsp")

  local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
  )

  require("mason").setup()

  require("mason-lspconfig").setup({
    ensure_installed = {
      "lua_ls",
      "pyright",
      "ltex",
      "marksman",
      "dockerls",
      "clangd",
    },
    automatic_enable = {
      exclude = { "clangd" },
    },
  })

  -- Apply capabilities to all servers
  vim.lsp.config('*', { capabilities = capabilities })

  -- lua_ls: suppress false 'vim' global warning
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
      },
    },
  })

  -- Enable standard servers (nvim-lspconfig provides their base configs)
  vim.lsp.enable({ 'pyright', 'ltex', 'marksman', 'dockerls', 'lua_ls' })

  -- clangd: started manually so we can inject --compile-commands-dir dynamically
  -- The colcon package name (package.xml <name>) can differ from the
  -- source folder name (e.g. repo "tii-lio" builds package "lidar_mapping_test"),
  -- so the build dir under build/ won't match root_dir's basename.
  local function colcon_package_name(root_dir)
    local pkg_xml = root_dir .. "/package.xml"
    if vim.fn.filereadable(pkg_xml) == 1 then
      for _, line in ipairs(vim.fn.readfile(pkg_xml)) do
        local name = line:match("<name>%s*([^<%s]+)%s*</name>")
        if name then return name end
      end
    end
    return vim.fn.fnamemodify(root_dir, ":t")
  end

  -- Fallback: scan build/*/compile_commands.json for one whose entries
  -- reference a file under root_dir.
  local function find_db_referencing(ws_dir, root_dir)
    for _, db_path in ipairs(vim.fn.glob(ws_dir .. "/build/*/compile_commands.json", true, true)) do
      local ok, content = pcall(vim.fn.readfile, db_path)
      if ok and table.concat(content, "\n"):find(root_dir, 1, true) then
        return vim.fn.fnamemodify(db_path, ":h")
      end
    end
    return nil
  end

  local function find_compile_commands_dir(root_dir)
    if vim.fn.filereadable(root_dir .. "/compile_commands.json") == 1 then
      return root_dir
    end
    if vim.fn.filereadable(root_dir .. "/build/compile_commands.json") == 1 then
      return root_dir .. "/build"
    end
    -- ROS2 / colcon: walk up until we find build/ install/ src/
    local dir = root_dir
    for _ = 1, 6 do
      local parent = vim.fn.fnamemodify(dir, ":h")
      if parent == dir then break end
      dir = parent
      if vim.fn.isdirectory(dir .. "/build") == 1 and
         vim.fn.isdirectory(dir .. "/install") == 1 and
         vim.fn.isdirectory(dir .. "/src") == 1 then
        local pkg_name = colcon_package_name(root_dir)
        local pkg_db = dir .. "/build/" .. pkg_name .. "/compile_commands.json"
        if vim.fn.filereadable(pkg_db) == 1 then
          return dir .. "/build/" .. pkg_name
        end
        local found = find_db_referencing(dir, root_dir)
        if found then return found end
        if vim.fn.filereadable(dir .. "/build/compile_commands.json") == 1 then
          return dir .. "/build"
        end
        break
      end
    end
    return nil
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
    callback = function(ev)
      local root_dir = vim.fs.root(ev.buf, {
        "package.xml", "CMakeLists.txt", "compile_commands.json", ".git"
      })
      if not root_dir then return end

      local cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=never",
        "--fallback-style=llvm",
        "--query-driver=/usr/lib/ccache/*,/usr/bin/g++,/usr/bin/gcc,/usr/bin/clang++,/usr/bin/clang",
      }
      local db_dir = find_compile_commands_dir(root_dir)
      if db_dir then
        table.insert(cmd, "--compile-commands-dir=" .. db_dir)
      end

      vim.notify("clangd starting with db: " .. (db_dir or "none"), vim.log.levels.INFO)
      vim.lsp.start({
        name = "clangd",
        cmd = cmd,
        root_dir = root_dir,
        capabilities = capabilities,
      })
    end,
  })

  -- Diagnostic display config
  vim.diagnostic.config({
    virtual_text = false,
    signs = {
      priority = 1,
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN]  = "",
        [vim.diagnostic.severity.INFO]  = "",
        [vim.diagnostic.severity.HINT]  = "",
      },
    },
    update_in_insert = false,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })

  vim.keymap.set("n", "<leader>dt", function()
      local is_enabled = vim.diagnostic.is_enabled()
      vim.diagnostic.enable(not is_enabled)
      print("Diagnostics " .. (not is_enabled and "Enabled" or "Disabled"))
  end, { desc = "Toggle Diagnostics" })

  local cmp_select = { behaviour = cmp.SelectBehavior.Select }

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
