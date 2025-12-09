local M = {}

function M.setup()
  local autopairs_enabled = false

  local function enable_autopairs()
    vim.keymap.set("i", "(", "()<Left>", { desc = "autopairs: ()" })
    vim.keymap.set("i", "[", "[]<Left>", { desc = "autopairs: []" })
    vim.keymap.set("i", "{", "{}<Left>", { desc = "autopairs: {}" })
    vim.keymap.set("i", "\"", "\"\"<Left>", { desc = "autopairs: \"\"" })
    vim.keymap.set("i", "'", "''<Left>", { desc = "autopairs: ''" })
    autopairs_enabled = true
    vim.notify("Autopairs enabled")
  end

  local function disable_autopairs()
    vim.keymap.del("i", "(")
    vim.keymap.del("i", "[")
    vim.keymap.del("i", "{")
    vim.keymap.del("i", "\"")
    vim.keymap.del("i", "'")
    autopairs_enabled = false
    vim.notify("Autopairs disabled")
  end

  local function toggle_autopairs()
    if autopairs_enabled then
      disable_autopairs()
    else
      enable_autopairs()
    end
  end

  vim.api.nvim_create_user_command("EnableAutopairs", enable_autopairs, {})
  vim.api.nvim_create_user_command("DisableAutopairs", disable_autopairs, {})
  vim.api.nvim_create_user_command("ToggleAutopairs", toggle_autopairs, {})
  -- Toggle-Key (frei wählbar)
  vim.keymap.set("n", "<leader>ap", toggle_autopairs, { desc = "Toggle autopairs remaps" })
end

return M
