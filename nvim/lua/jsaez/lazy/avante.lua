return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  opts = {
    provider = "copilot",
    auto_suggestions_provider = "copilot",
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = false,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
      minimize_diff = true,
      enable_cursor_planning_mode = true,
    },
    providers = {
      copilot = {},
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-5-sonnet-20241022",
        timeout = 30000,
        extra_request_body = {
          temperature = 0,
          max_tokens = 8000,
        },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "nvim-treesitter/nvim-treesitter",
    "zbirenbaum/copilot.lua",
  },
  keys = {
    { "<leader>aa", "<cmd>AvanteAsk<cr>", desc = "Avante: Ask" },
    { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "Avante: Edit" },
    { "<leader>ac", "<cmd>AvanteChat<cr>", desc = "Avante: Chat" },
    { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Avante: Toggle" },
    { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "Avante: Refresh" },
    {
      "<leader>ap",
      function()
        local providers = { "copilot", "claude" }

        vim.ui.select(providers, { prompt = "Avante provider:" }, function(choice)
          if choice then
            vim.cmd("AvanteSwitchProvider " .. choice)
          end
        end)
      end,
      desc = "Avante: Switch Provider",
    },
  },
}
