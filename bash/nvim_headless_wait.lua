-- Run by setup_dotfiles.sh after `Lazy! install` in a headless nvim.
-- The plugin configs queue treesitter parsers and Mason packages in the
-- background at startup; without waiting, `+qa` kills them half-way and every
-- setup run starts them again. Block until they are done (or time out).
local timeout_ms = 800000

-- Parser list mirrors nvim/lua/jsaez/lazy/treesitter.lua (already-installed
-- parsers are skipped, so this only waits for what is still missing).
local ok_ts, ts = pcall(require, "nvim-treesitter.install")
if ok_ts then
    pcall(function()
        ts.install({ "vimdoc", "python", "cpp", "c", "lua" }):wait(timeout_ms)
    end)
end

local ok_mason, registry = pcall(require, "mason-registry")
if ok_mason then
    vim.wait(5000) -- give registry.refresh()/ensure_installed time to queue their packages
    vim.wait(timeout_ms, function()
        for _, pkg in ipairs(registry.get_all_packages()) do
            if pkg:is_installing() then
                return false
            end
        end
        return true
    end, 500)
end
