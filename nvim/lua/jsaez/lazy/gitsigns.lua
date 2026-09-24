return {
  "lewis6991/gitsigns.nvim",
  config = function()
    local signs = {
      add          = { text = '┃' },
      change       = { text = '┃' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    }
    require('gitsigns').setup {
      signs = signs,
      signs_staged = signs,
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
    }

    local gs = require('gitsigns')

    vim.keymap.set('n', ']h', gs.next_hunk,  { desc = "Next hunk" })
    vim.keymap.set('n', '[h', gs.prev_hunk,  { desc = "Prev hunk" })

    vim.keymap.set('n', '<leader>ga', gs.stage_hunk,        { desc = "Stage hunk" })
    vim.keymap.set('n', '<leader>gu', gs.undo_stage_hunk,   { desc = "Undo stage hunk" })
    vim.keymap.set('n', '<leader>gp', gs.preview_hunk,      { desc = "Preview hunk" })
    vim.keymap.set('n', '<leader>gw', function() gs.blame_line({ full = true }) end, { desc = "Blame line" })

    vim.keymap.set('n', '<leader>gi', gs.diffthis,                      { desc = "Diff vs index" })
    vim.keymap.set('n', '<leader>gh', function() gs.diffthis('~1') end, { desc = "Diff vs HEAD~1" })
  end,
}
