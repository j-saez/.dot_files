return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup {}

    local legend_win = nil
    local legend_buf = nil

    local lines = {
      "  o / ↵   open file      ",
      "  a        create        ",
      "  d        delete        ",
      "  r        rename        ",
      "  x / c    cut / copy    ",
      "  p        paste         ",
      "  R        refresh       ",
      "  H        toggle hidden ",
      "  -        up dir        ",
      "  q        close         ",
      "  ?        full help     ",
    }

    local function get_buf()
      if legend_buf and vim.api.nvim_buf_is_valid(legend_buf) then
        return legend_buf
      end
      legend_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(legend_buf, 0, -1, false, lines)
      vim.bo[legend_buf].modifiable = false
      vim.bo[legend_buf].bufhidden = "hide"
      return legend_buf
    end

    local function show()
      if legend_win and vim.api.nvim_win_is_valid(legend_win) then return end
      local tree_win = vim.api.nvim_get_current_win()
      local h = vim.api.nvim_win_get_height(tree_win)
      local w = vim.api.nvim_win_get_width(tree_win)
      legend_win = vim.api.nvim_open_win(get_buf(), false, {
        relative = "win",
        win = tree_win,
        row = h - #lines - 2,
        col = 1,
        width = w - 2,
        height = #lines,
        style = "minimal",
        border = "rounded",
        focusable = false,
        zindex = 50,
      })
      vim.wo[legend_win].winblend = 15
    end

    local function hide()
      if legend_win and vim.api.nvim_win_is_valid(legend_win) then
        vim.api.nvim_win_close(legend_win, true)
      end
      legend_win = nil
    end

    local grp = vim.api.nvim_create_augroup("NvimTreeLegend", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = grp,
      callback = function()
        if vim.bo.filetype == "NvimTree" then show() end
      end,
    })
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
      group = grp,
      callback = function()
        if vim.bo.filetype == "NvimTree" then hide() end
      end,
    })
  end,
  keys = {
    { "<leader>ee", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
  },
}
