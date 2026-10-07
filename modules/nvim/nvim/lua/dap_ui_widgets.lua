return {
  setup = function()
    local dap = require("dap")
    local widgets = require("dap.ui.widgets")

    -- Floating “scopes” (Variablen im aktuellen Frame)
    vim.keymap.set("n", "<leader>ds", function()
      widgets.centered_float(widgets.scopes)
    end, { desc = "DAP: Scopes (float)" })

    -- Floating “frames” (Call stack)
    vim.keymap.set("n", "<leader>df", function()
      widgets.centered_float(widgets.frames)
    end, { desc = "DAP: Stackframes (float)" })

    -- Floating “threads” (falls du brauchst)
    vim.keymap.set("n", "<leader>dt", function()
      widgets.centered_float(widgets.threads)
    end, { desc = "DAP: Threads (float)" })

    require("nvim-dap-virtual-text").setup { virt_text_pos = "eol" }
  end
}
