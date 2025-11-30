local M = {}

-- TODO: blabla
function M.setup()
  require("todo-comments").setup {
    keywords = {
      TODO  = { icon = " ", color = "info" },
      FIX   = { icon = " ", color = "error", alt = { "FIXME", "BUG" } },
      HACK  = { icon = " ", color = "warning" },
      NOTE  = { icon = " ", color = "hint", alt = { "INFO" } },
    },
    highlight = {
      multiline = true,
    },
    search = {
      command = "rg",
      args = {
        "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column",
      },
      pattern = [[\b(KEYWORDS):]], -- KEYWORDS wird oben ersetzt
    },
  }
end

return M
