-- Custom grep finder that parses "query  <filter>" (two spaces) to narrow results.
-- ".ext" or "ext" both filter by extension glob (e.g. "hola  .lua" or "hola  lua" -> --glob "*.lua")
-- Works with an empty query too: "  .lua" lists all matches in Lua files.
local function grep_with_ext_filter(opts, ctx)
  local saved_search = ctx.filter.search
  local saved_glob = opts.glob
  local saved_need_search = opts.need_search
  local sep = saved_search:find("  ")
  if sep then
    local search_term = saved_search:sub(1, sep - 1)
    local ext_str = vim.trim(saved_search:sub(sep + 2))
    ctx.filter.search = search_term
    if ext_str ~= "" then
      local ext = ext_str:match("^%.(.+)") or ext_str
      local base = type(opts.glob) == "table" and vim.deepcopy(opts.glob)
        or (opts.glob and { opts.glob } or {})
      opts.glob = vim.list_extend(base, { "*." .. ext })
      opts.need_search = false
    end
  end
  local result = require("snacks.picker.source.grep").grep(opts, ctx)
  ctx.filter.search = saved_search
  opts.glob = saved_glob
  opts.need_search = saved_need_search
  return result
end

-- Builds filter opts for the files picker that support "query  .ext" double-space syntax.
-- Uses filter.opts.transform to strip the extension suffix from the fuzzy pattern before matching,
-- and filter.opts.filter to hard-exclude files that don't have the requested extension.
-- This keeps the picker non-live so fuzzy name matching is fully preserved.
local function make_files_ext_filter()
  local active_ext = nil
  return {
    transform = function(picker, filter)
      local sep = filter.pattern:find("  ")
      if sep then
        local ext_str = vim.trim(filter.pattern:sub(sep + 2))
        filter.pattern = vim.trim(filter.pattern:sub(1, sep - 1))
        active_ext = ext_str ~= "" and (ext_str:match("^%.(.+)") or ext_str) or nil
      else
        active_ext = nil
      end
    end,
    filter = function(item)
      if active_ext then
        local file = item.file or item.text or ""
        return file:match("%." .. vim.pesc(active_ext) .. "$") ~= nil
      end
      return true
    end,
  }
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    input = { enabled = true },
    notifier = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        files = {
          hidden = true,
          exclude = {
            ".git",
            "build",
            "install",
            "log",
          },
        },
        grep = {
          hidden = true,
          exclude = {
            ".git",
            "build",
            "install",
            "log",
          },
        },
      },
    },
  },
  keys = {
    { "<leader>ff", function()
        Snacks.picker.files({ filter = make_files_ext_filter() })
      end, desc = "Find Files (append '  .ext' to filter by extension)" },
    { "<leader>fg", function()
        Snacks.picker.grep({ finder = grep_with_ext_filter })
      end, desc = "Grep (append '  .ext' to filter by extension)" },
    { "<leader>gg", function()
        Snacks.picker.grep({ dirs = { vim.fn.expand("%:p") } })
      end, desc = "Grep Current Buffer" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Tags" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    { "<leader>fW", function() Snacks.picker.grep_word({ word = true }) end, desc = "Grep WORD", mode = { "n", "x" } },
    { "<space>fg", function()
        Snacks.picker.grep({ finder = grep_with_ext_filter })
      end, desc = "Grep" },
    { "<leader>fc", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },

    { "<leader>gl", function() Snacks.picker.git_log()      end, desc = "Git log" },
    { "<leader>gL", function() Snacks.picker.git_log_file() end, desc = "Git log (current file)" },
    { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git branches" },
    { "<leader>gS", function() Snacks.picker.git_status()   end, desc = "Git status picker" },
  },
}
