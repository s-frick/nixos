local M = {}
local function has_server(list, name)
  if not list then return true end
  for _, n in ipairs(list) do
    if n == name then return true end
  end
end

local mappings = {
  -- Navigation
  { mode =  "n", lhs =  "<leader>-" , rhs =  ":split <CR>" , desc = "Horizontal Split", scope = "global" },
  { mode =  "n", lhs =  "<leader>\\", rhs =  ":vsplit <CR>", desc = "Vertical Split", scope = "global" },
  { mode =  "n", lhs =  "<leader>q" , rhs =  ":q <CR>"     , desc = "Close Buffer", scope = "global" },
  { mode =  "n", lhs =  "<leader>qq", rhs =  ":qa <CR>"    , desc = "Close All Buffer", scope = "global" },
  { mode =  "n", lhs =  "<leader>e" , rhs =  ":Ex <CR>"    , desc = "Filetree", scope = "global" },

  -- Telescope
  -- { mode = "", lhs = "", rhs = "", desc = "", scope = "" },
  { mode="n" , lhs="gi"               , rhs=require('telescope.builtin').lsp_implementations , desc="Gotoimplementation" , scope="lsp" },
  { mode="n" , lhs="gr"               , rhs=require('telescope.builtin').lsp_references      , desc="References"         , scope="lsp" },
  { mode="n" , lhs="<leader>sf"       , rhs=require('telescope.builtin').find_files          , desc="Findfiles"          , scope="global" },
  { mode="n" , lhs="<leader>sg"       , rhs=require('telescope.builtin').live_grep           , desc="Livegrep"           , scope="global" },
  { mode="n" , lhs="<leader><leader>" , rhs=require('telescope.builtin').buffers             , desc="Buffers"            , scope="global" },
  { mode="n" , lhs="<leader>sh"       , rhs=require('telescope.builtin').help_tags           , desc="Helptags"           , scope="global" },

  -- Lsp
  { mode = "n", lhs = "K"    , rhs = vim.lsp.buf.hover         , desc = "Hover docs", scope = "lsp"},
  { mode = "n", lhs = "<C-k>", rhs = vim.lsp.buf.signature_help, desc = "Signature help", scope = "lsp"},
  { mode = "n", lhs = "gd"   , rhs = vim.lsp.buf.definition    , desc = "Go to definition", scope = "lsp"},
  { mode = "n", lhs = "gD"   , rhs = vim.lsp.buf.declaration   , desc = "Go to declaration", scope = "lsp"},


  -- Refactor/ Code Actions
  { mode = "n", lhs = "<leader>rn", rhs = vim.lsp.buf.rename, desc = "Rename symbol", scope = "lsp"},
  { mode = { "n", "v" }, lhs =  "<leader>ca", rhs = vim.lsp.buf.code_action, desc = "Code action", scope = "lsp"},
  { mode = { "n", "v" }, lhs = "<leader>cf",
    rhs = function()
      if vim.lsp.buf.format then
        vim.lsp.buf.format({ async = true })
      end
    end, desc = "Format buffer", scope = "lsp"},

  -- Diagnostics
  { mode = "n", lhs = "[d", rhs = vim.diagnostic.goto_prev, desc = "Prev diagnostic", scope = "global"},
  { mode = "n", lhs = "]d", rhs = vim.diagnostic.goto_next, desc = "Next diagnostic", scope = "global"},
  { mode = "n", lhs = "<leader>de", rhs = vim.diagnostic.open_float, desc = "Line diagnostics", scope = "global"},
  { mode = "n", lhs = "<leader>dl", rhs = vim.diagnostic.setloclist, desc = "Diagnostics → loclist", scope = "global"},

  -- Misc
  { mode = "n", lhs = "<leader>li", rhs = "<cmd>LspInfo<CR>", desc = "LSP info", scope = "global"},
  { mode = "n", lhs = "<Esc>", rhs = ":nohlsearch<CR>" ,desc = "Clear Highlight", scope = "global" }

}

-- global maps
function M.setup()
  for _, m in ipairs(mappings) do
    if m.scope == "global" then
      vim.keymap.set(
        m.mode,
        m.lhs,
        m.rhs,
        { desc = m.desc, silent = true, noremap = true }
      )
    end
  end
end

-- on_attach for LSP stuff
function M.on_attach(client, bufnr)
  for _, m in ipairs(mappings) do
    if m.scope == "lsp" and has_server(m.servers, client.name) then
      vim.keymap.set(
        m.mode,
        m.lhs,
        m.rhs,
        { desc = m.desc, buffer = bufnr, silent = true, noremap = true }
      )
    end
  end
end



pcall(function()
	local wk = require("which-key")
	wk.add({
		mode = { "n" },
		{ "<leader>l", group = "LSP" },
		{ "<leader>t", group = "Toggle" },
		{ "<leader>d", group = "Diagnostics" },
		{ "<leader>c", group = "Code Actions" },
		{ "<leader>f", group = "Find Stuff" },
	})
end)

return M
