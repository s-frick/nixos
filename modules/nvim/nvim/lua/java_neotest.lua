local M = {}

function M.setup()
  local neotest = require("neotest")

  neotest.setup({
    adapters = {
      require("neotest-jdtls"),  -- oder require("neotest-java")({ ... })
    },
  })

  vim.g.neotest_jdtls_log_level = "debug"
  -- Keymaps
  vim.keymap.set("n", "<leader>tn", function()
    neotest.run.run()                         -- nearest
  end, { desc = "Neotest: nearest test" })

  vim.keymap.set("n", "<leader>tN", function()
    neotest.run.run(vim.fn.expand("%"))       -- aktuelle Datei
  end, { desc = "Neotest: file" })

  vim.keymap.set("n", "<leader>tA", function()
    neotest.run.run({ suite = true })           -- gesamtes Projekt / cwd
  end, { desc = "Neotest: all tests (project)" })

  vim.keymap.set("n", "<leader>ts", function()
    neotest.summary.toggle()                  -- Übersicht
  end, { desc = "Neotest: summary" })

  vim.keymap.set("n", "<leader>to", function()
    neotest.output.open({ enter = true })     -- Output für letzten Run
  end, { desc = "Neotest: output" })
end

return M
