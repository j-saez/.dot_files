return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require('gitsigns').setup {
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged_enable = true,
      signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
      numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        follow_files = true
      },
      auto_attach = true,
      attach_to_untracked = false,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
        use_focus = true,
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000, -- Disable if file is longer than this (in lines)
      preview_config = {
        -- Options passed to nvim_open_win
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },
    }

    local gs = require('gitsigns')

    vim.keymap.set('n', ']h', gs.next_hunk,  { desc = "Next hunk" })
    vim.keymap.set('n', '[h', gs.prev_hunk,  { desc = "Prev hunk" })

    vim.keymap.set('n', '<leader>hs', gs.stage_hunk,        { desc = "Stage hunk" })
    vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk,   { desc = "Undo stage hunk" })
    vim.keymap.set('n', '<leader>hp', gs.preview_hunk,      { desc = "Preview hunk" })
    vim.keymap.set('n', '<leader>hb', function() gs.blame_line({ full = true }) end, { desc = "Blame line" })

    vim.keymap.set('n', '<leader>hd', gs.diffthis,                      { desc = "Diff vs index" })
    vim.keymap.set('n', '<leader>hD', function() gs.diffthis('~1') end, { desc = "Diff vs HEAD~1" })
  end,
}
