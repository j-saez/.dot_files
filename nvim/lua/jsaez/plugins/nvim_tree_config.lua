-- Nvim tree setup
-- For complete list of available configuration options see :help nvim-tree-setup
-- Each option is documented in :help nvim-tree.OPTION_NAME. Nested options can be accessed by appending ., for example :help nvim-tree.view.mappings

-- empty setup using defaults
--require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
      },
    },
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})
