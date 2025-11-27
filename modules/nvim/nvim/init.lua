-- Leader
vim.g.mapleader = " "

-- Basics
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus" -- nutzt unter WSL win32yank

-- File handling
vim.opt.backup = false -- Don't create backup files
vim.opt.writebackup = false -- Don't create backup before writing
vim.opt.swapfile = false -- Don't create swap files
vim.opt.undofile = true -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300 -- Faster completion
vim.opt.timeoutlen = 300 -- Key timeout duration
vim.opt.ttimeoutlen = 0 -- Key code timeout
vim.opt.ttimeout = true
vim.opt.autoread = true -- Auto reload files changed outside vim
vim.opt.autowrite = false -- Don't auto save

local keymap = require('keymaps')
keymap.setup()

-- Theme
vim.cmd.colorscheme("catppuccin")


-- Treesitter: Parser in ein beschreibbares Verzeichnis legen (nicht im Nix-Store)
local parser_path = vim.fn.stdpath("data") .. "/treesitter-parsers"
vim.fn.mkdir(parser_path, "p") -- Ordner sicher anlegen
vim.opt.runtimepath:append(parser_path) -- RTP, damit Neovim dort .so findet

require("nvim-treesitter.install").prefer_git = false
require("nvim-treesitter.install").compilers = {} -- verhindert Build-Versuche auf Systemen ohne Toolchain

require("nvim-treesitter.configs").setup({
	parser_install_dir = parser_path,
	ensure_installed = {}, -- wir verlassen uns auf Nix/Plugins, nicht auf TS-Installer
	auto_install = false, -- keine Auto-Downloads (würden sonst wieder in den Store wollen)
	highlight = { enable = true },
	indent = { enable = true },
  modules = {},
  ignore_install = {},
  sync_install = false
})

-- Lualine
require("lualine").setup({
	options = { theme = "auto", globalstatus = true },
})

-- Gitsigns
require("gitsigns").setup({})

-- Completion
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  preselect = cmp.PreselectMode.Item,
  completion = {
    completeopt = "menu,menuone",
    autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
  },
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),

    -- Navigation
    ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
    ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),

		["<C-y>"] = cmp.mapping.confirm({ select = false }),
    ["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.abort()
      end
      fallback()
    end, { "i", "s" }),
		["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.abort()
      end
      fallback()
    end, { "i", "s" }),
		["<S-Tab>"] = function() end,
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "path" },
		{ name = "buffer" },
		{ name = "luasnip" },
	}),
})

-- LSP
-- ===== Ruhe reinbringen: LSP-Handler runterdrehen =====
-- Nur WARN/ERROR anzeigen, INFO/DEBUG ignorieren:
vim.lsp.set_log_level("ERROR")

-- Server-Logs nicht spammen:
vim.lsp.handlers["window/logMessage"] = function() end
vim.lsp.handlers["$/progress"] = function() end
vim.lsp.handlers["language/status"] = function() end

-- Popups mit Buttons (z.B. "Update project configuration?") automatisch bestätigen:
vim.lsp.handlers["window/showMessageRequest"] = function(_, result)
	local actions = result.actions or {}
	-- wähle die erste Aktion (meist "Always"/"Proceed"/"Yes")
	if #actions > 0 then
		return actions[1]
	end
end

-- ===== LSP UX: Diagnostics, Signs, Keymaps, on_attach =====

-- hübschere Diagnostics
vim.diagnostic.config({
	virtual_text = false, -- weniger Rauschen im Text
	float = { border = "rounded" },
	severity_sort = true,
	signs = true,
	underline = true,
})
-- Zeichen in der Zeichenleiste
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local util = lspconfig.util

-- Lua (Neovim)
lspconfig.lua_ls.setup({
	capabilities = capabilities,
	on_attach = keymap.on_attach,
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      completion = {
        callSnippet = "Replace"
      },
			telemetry = { enable = false },
		},
	},
})

-- Typescript
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	on_attach = keymap.on_attach,
	cmd = { "typescript-language-server", "--stdio" },
	root_dir = util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
	single_file_support = false,
	settings = {
		typescript = {
			preferGoToSourceDefinition = true,
			format = { semicolons = "insert" },
			inlayHints = {
				enumMemberValues = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				variableTypes = { enabled = true },
			},
			suggest = {
				completeFunctionCalls = true,
				includeCompletionsForImportStatements = true,
			},
		},
		javascript = {
			preferGoToSourceDefinition = true,
			inlayHints = { enumMemberValues = { enabled = true } },
		},
	},
})
-- ===== ESLint LSP (optional, wenn installiert) =====
-- funktioniert gut parallel zu ts_ls, steuert nur Diagnostics/Fixes von ESLint
if vim.fn.executable("vscode-eslint-language-server") == 1 then
	lspconfig.eslint.setup({
		capabilities = capabilities,
		cmd = { "vscode-eslint-language-server", "--stdio" },
		root_dir = util.root_pattern(
			".eslintrc",
			".eslintrc.js",
			".eslintrc.cjs",
			".eslintrc.json",
			"package.json",
			".git"
		),
		settings = {
			workingDirectory = { mode = "auto" },
			format = true,
		},
	})
end
-- Autoformat via prettierd oder prettier, falls verfügbar
local function format_with_prettier(bufnr)
	local has_prettierd = vim.fn.executable("prettierd") == 1
	local cmd = has_prettierd and "prettierd" or (vim.fn.executable("prettier") == 1 and "prettier" or nil)
	if not cmd then
		return
	end
	local ft = vim.bo[bufnr].filetype
	local exts = {
		typescript = "ts",
		typescriptreact = "tsx",
		javascript = "js",
		javascriptreact = "jsx",
		json = "json",
		css = "css",
		html = "html",
		markdown = "md",
		yaml = "yaml",
	}
	local ext = exts[ft]
	if not ext then
		return
	end
	-- nutze stdin, respektiere Projektconfigs
	vim.cmd("silent write")
	vim.fn.jobstart({ cmd, "--stdin-filepath", vim.api.nvim_buf_get_name(bufnr) }, { stdin = "pipe" })
end

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.json", "*.css", "*.html", "*.md", "*.yaml", "*.yml" },
	callback = function(args)
		format_with_prettier(args.buf)
	end,
})

-- Nix
lspconfig.nixd.setup({
	capabilities = capabilities,
	on_attach = keymap.on_attach,
})

-- ======================================
-- Java LSP (Eclipse JDT LS)
-- ======================================
local home = os.getenv("HOME")
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

local workspace_dir = home .. "/.local/share/eclipse/" .. project_name
os.execute("mkdir -p " .. workspace_dir)

lspconfig.jdtls.setup({
	capabilities = capabilities,
	on_attach = keymap.on_attach,
	cmd = { "jdtls-lombok" },
	root_dir = lspconfig.util.root_pattern("pom.xml", "build.gradle", ".git"),
	settings = {
		java = {
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" },
			completion = {
				guessMethodArguments = false,
				favoriteStaticMembers = {
					"org.junit.Assert.*",
					"org.junit.Assume.*",
					"org.junit.jupiter.api.Assertions.*",
					"org.junit.jupiter.api.Assumptions.*",
					"org.mockito.Mockito.*",
				},
			},
			sources = {
				organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
			},
			configuration = {
				updateBuildConfiguration = "automatic",
				runtimes = {
					{
						name = "JavaSE-21",
						path = vim.fn.expand("~/.nix-profile/lib/openjdk"),
					},
				},
			},
			project = {
				-- Unterdrückt "Import project?"-Hinweise
				importHint = false,
			},
			import = {
				-- automatisch Maven/Gradle importieren
				maven = { enabled = true },
				gradle = { enabled = true, wrapper = { enabled = true } },
				-- früheres Setting in VSCode: project.importOnFirstTimeStartup=automatic
			},
			eclipse = { downloadSources = true },
			maven = { downloadSources = true },

			-- Weniger “interaktive” Features = weniger Lärm:
			implementationsCodeLens = { enabled = true },
			referencesCodeLens = { enabled = true },
			references = { includeDecompiledSources = true },
			format = { enabled = true }, -- falls Formatter-Prompts nerven
		},
	},
	init_options = {
		workspace = workspace_dir,
		workspaceFolders = { vim.uri_from_fname(vim.fn.getcwd()) },
	},
})
-- vim.keymap.set("n", "<leader>gi", function() vim.lsp.buf.implementation() end, { desc = "Java: Go to implementation" })
-- vim.keymap.set("n", "<leader>gr", function() vim.lsp.buf.references() end, { desc = "Java: Find references" })
-- vim.keymap.set("n", "<leader>go", function() vim.lsp.buf.document_symbol() end, { desc = "Java: Outline" })

-- Format on save (Beispiel: Lua via stylua, Shell via shfmt)
local format_augroup = vim.api.nvim_create_augroup("FormatOnSave", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = format_augroup,
	pattern = { "*.lua" },
	callback = function()
		vim.cmd("silent! !stylua %")
	end,
})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = format_augroup,
	pattern = { "*.sh" },
	callback = function()
		vim.cmd("silent! !shfmt -w %")
	end,
})

-- FeMaco: Edit fenced code blocks with LSP
require("femaco").setup({
	-- optional: window opts etc.
})

-- Keymap: Cursor auf Codefence/inline-Block stellen und dann:
vim.keymap.set("n", "<leader>fe", function()
	require("femaco.edit").edit_code_block()
end, { desc = "Edit fenced codeblock (LSP)" })
