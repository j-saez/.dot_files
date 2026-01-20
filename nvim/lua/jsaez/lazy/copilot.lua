return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    local nvm_dir = vim.env.NVM_DIR or (vim.env.HOME .. "/.nvm")
    local nvm_dir_escaped = vim.fn.shellescape(nvm_dir)
    local node_cmd = table.concat({
      "bash -lc '",
      "export NVM_DIR=" .. nvm_dir_escaped .. "; ",
      "[ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"; ",
      "command -v node'",
    })
    local node = vim.fn.systemlist(node_cmd)[1]
    if node == nil or node == "" then
      node = "node"
    end

    require("copilot").setup({
      copilot_node_command = node,
    })
  end,
}
