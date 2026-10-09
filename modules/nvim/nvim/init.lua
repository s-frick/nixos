-- projektlokale Konfigurationen zulassen
vim.o.exrc = true
-- Leader
vim.g.mapleader = " "

-- Optional remote plugin providers not used by this config
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

-- Basics
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus" -- nutzt unter WSL win32yank
vim.opt.winborder = 'rounded'

-- File handling
vim.opt.backup = false                            -- Don't create backup files
vim.opt.writebackup = false                       -- Don't create backup before writing
vim.opt.swapfile = false                          -- Don't create swap files
vim.opt.undofile = true                           -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300                          -- Faster completion
vim.opt.timeoutlen = 300                          -- Key timeout duration
vim.opt.ttimeoutlen = 0                           -- Key code timeout
vim.opt.ttimeout = true
vim.opt.autoread = true                           -- Auto reload files changed outside vim
vim.opt.autowrite = false                         -- Don't auto save

vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 5
vim.opt.scrolloff = 10
vim.opt.linebreak = true -- wrap nur an Wortgrenzen
vim.opt.breakindent = true

local autopairs = require("autopairs")
autopairs.setup()

local keymap = require("keymaps")
keymap.setup()

local todo_comments = require("todo_comments")
todo_comments.setup()

-- Theme
require("gruber-darker").setup({
  bold = true,
  italic = {
    strings = false,
    comments = true,
    operators = false,
    folds = true,
  },
})
vim.cmd.colorscheme("gruber-darker")

-- Lualine
require("lualine").setup({
  options = { theme = "auto", globalstatus = true },
})

require("treesitter").setup()
require("dap_ui_widgets").setup()

-- Gitsigns
require("gitsigns").setup({})
require("completion").setup()

-- Copilot (only installed when my.nvim.copilot.enable): <Tab> belongs to nvim-cmp
vim.g.copilot_no_tab_map = true
vim.keymap.set("i", "<C-j>", function()
  if vim.fn.exists("*copilot#Accept") == 1 then
    return vim.fn["copilot#Accept"]("")
  end
  return ""
end, { expr = true, replace_keycodes = false, desc = "Copilot accept" })

-- Avante (agentic chat, uses the Copilot login from :Copilot setup)
local has_avante, avante = pcall(require, "avante")
if has_avante then
  avante.setup({ provider = "copilot" })
end

-- Neo-tree
require("neo_tree").setup()

-- Mermaid (.mmd/.mermaid): Preview, Format, Lint via mmdc
require("mermaid").setup()
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mermaid",
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("<leader>mp", "<cmd>MermaidPreview<CR>", "Mermaid Preview")
    map("<leader>mx", "<cmd>MermaidPreviewStop<CR>", "Mermaid Stop Preview")
    map("<leader>mf", "<cmd>MermaidFormat<CR>", "Mermaid Format")
    map("<leader>mr", "<cmd>MermaidRender<CR>", "Mermaid Render")
    map("<leader>mc", "<cmd>MermaidCopyURL<CR>", "Mermaid Copy URL")
  end,
})

-- LSP
-- vim.lsp.set_log_level("ERROR")
-- vim.lsp.handlers["window/logMessage"] = function() end
-- vim.lsp.handlers["$/progress"] = function() end
-- vim.lsp.handlers["language/status"] = function() end

-- Popups mit Buttons (z.B. "Update project configuration?") automatisch bestätigen:
-- vim.lsp.handlers["window/showMessageRequest"] = function(_, result)
--   local actions = result.actions or {}
--   -- wähle die erste Aktion (meist "Always"/"Proceed"/"Yes")
--   if #actions > 0 then
--     return actions[1]
--   end
-- end

-- ===== LSP UX: Diagnostics, Signs, Keymaps, on_attach =====

-- Diagnostic configuration mit neuer API (Neovim 0.11+)
vim.diagnostic.config({
  virtual_text = false, -- weniger Rauschen im Text
  float = { border = "rounded" },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E ",
      [vim.diagnostic.severity.WARN] = "⚠",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    }
  },
  underline = true,
})

-- Server-Overrides liegen in after/lsp/<name>.lua (after/, damit sie nvim-lspconfig schlagen)
vim.lsp.config('*', { capabilities = require("cmp_nvim_lsp").default_capabilities() })
vim.lsp.enable({ 'lua_ls', 'hls', 'ts_ls', 'kotlin_language_server', 'rust_analyzer', 'clangd', 'nixd' })


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    keymap.on_attach(client, args.buf)

    -- Formatting
    if not client:supports_method('textDocument/willSaveWaitUntil')
        and client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ async = false, id = args.data.client_id, timeout_ms = 1500 })
        end
      })
    end
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    require("jdtls_setup").setup()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    require("todo-lists").setup()
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg == "" then
      return
    end

    local path = vim.fn.fnamemodify(arg, ":p")

    -- Wenn Datei → parent directory
    if vim.fn.isdirectory(path) == 0 then
      path = vim.fn.fnamemodify(path, ":h")
    end

    vim.cmd("cd " .. vim.fn.fnameescape(path))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lisp",
  callback = function()
    vim.opt_local.makeprg = "sbcl --script %"
    vim.api.nvim_cmd({ cmd = "EnableAutopairs" }, {})
    vim.keymap.set("n", "<leader>r", ":make<CR>")
  end,
})
