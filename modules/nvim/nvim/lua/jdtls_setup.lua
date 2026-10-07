-- ~/git/configs/nvim/lua/jdtls/jdtls_setup.lua
local M = {}

function M.setup()
  local jdtls = require("jdtls")

  local bufnr = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(bufnr)

  -- 1) jdt://-URIs ignorieren (dekompilierte Klassen)
  if fname:match("^jdt://") then
    return
  end

  -- Root (Maven/Gradle/Git)
  local root_markers = { "pom.xml", "build.gradle", "settings.gradle", ".git" }
  local root_dir = require("jdtls.setup").find_root({ ".git", ".jdtlsroot" })
  if root_dir and root_dir ~= "" then
    if vim.fn.filereadable(root_dir .. "/pom.xml") == 0 then
      -- No parent pom, fallback
      root_dir = require("jdtls.setup").find_root(root_markers)
    end
  end

  if not root_dir or root_dir == "" then
    return
  end

  -- Workspace pro Projekt
  local home = os.getenv("HOME")
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/.local/share/eclipse/" .. project_name
  vim.fn.mkdir(workspace_dir, "p")

  -- Bundles (Debug + Test) aus Env-Vars
  local bundles = {}

  -- Die Verzeichnisse kommen aus home.sessionVariables. Fehlen sie (z.B. Shell
  -- älter als der letzte home-manager switch), läuft jdtls ohne Debug/Test
  -- weiter statt den ganzen FileType-Autocmd zu sprengen.
  local debug_dir = os.getenv("JAVA_DEBUG_SERVER_DIR")
  local test_dir = os.getenv("JAVA_TEST_SERVER_DIR")
  local missing = {}

  -- Debug
  if debug_dir and debug_dir ~= "" then
    for _, jar in ipairs(vim.fn.glob(debug_dir .. "/com.microsoft.java.debug.plugin-*.jar", 1, 1)) do
      table.insert(bundles, jar)
    end
  else
    table.insert(missing, "JAVA_DEBUG_SERVER_DIR")
  end

  -- Test: alle OSGi-Bundles aus dem server-Verzeichnis, nicht nur das Plugin.
  -- Das Plugin benötigt u.a. org.eclipse.jdt.junit4.runtime, die jdtls selbst
  -- nicht mehr mitliefert — die Jars liegen im Extension-Verzeichnis daneben.
  -- Ausgenommen: Nicht-OSGi-Jars, die das Bundle-Loading brechen.
  if test_dir and test_dir ~= "" then
    for _, jar in ipairs(vim.fn.glob(test_dir .. "/*.jar", 1, 1)) do
      local name = vim.fn.fnamemodify(jar, ":t")
      if not name:match("runner%-jar%-with%-dependencies") and not name:match("jacocoagent") then
        table.insert(bundles, jar)
      end
    end
  else
    table.insert(missing, "JAVA_TEST_SERVER_DIR")
  end

  if #missing > 0 then
    vim.notify(
      "[jdtls] " .. table.concat(missing, ", ") .. " nicht gesetzt — Debug/Test-Bundles fehlen. "
      .. "Neue Login-Shell starten (exec zsh -l) bzw. tmux-Server neu starten.",
      vim.log.levels.WARN
    )
  end

  local cmd = { "jdtls", "-data", workspace_dir }

  local lombok_jar = os.getenv("LOMBOK_JAR")
  if lombok_jar and lombok_jar ~= "" then
    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
  end
  table.insert(cmd, "--jvm-arg=-Xmx8g")

  -- capabilities für LSP von nvim-cmp holen
  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  -- Standard-LSP-Keymaps setzt der LspAttach-Autocmd in init.lua
  local function on_attach(_, bufnr)
    -- Java-spezifische Keymaps
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "<leader>cc", "<cmd>JdtCompile<CR>", opts)
    vim.keymap.set("n", "<leader>tn", jdtls.test_nearest_method, { buffer = bufnr, desc = "Java: Test nearest" })
    vim.keymap.set("n", "<leader>tN", jdtls.test_class, { buffer = bufnr, desc = "Java: Test class" })

    local dap_ok, dap = pcall(require, "dap")
    if dap_ok then
      jdtls.setup_dap({ hotcodereplace = "auto" })
      if jdtls.setup_dap_main_class_config then
        jdtls.setup_dap_main_class_config()
      end
      -- launch.json wird automatisch von nvim-dap geladen
    end
  end

  local default_settings = {
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
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },

      configuration = {
        updateBuildConfiguration = "interactive",
      },

      project = {
        importHint = false,
      },

      import = {
        maven = { enabled = true, downloadSources = true },
        gradle = { enabled = true, wrapper = { enabled = true } },
      },

      eclipse = {
        downloadSources = true,
      },

      maven = {
        downloadSources = true,
        updateSnapshots = true,
        userSettings = home .. "/.m2/settings.xml"
      },

      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
      references = {
        enabled = true,
        includeDecompiledSources = true,
      },

      format = {
        enabled = true,
      },
    },
  }

  local settings = vim.tbl_deep_extend(
    "force",
    default_settings,
    vim.g.project_jdtls_settings or {}
  )

  local formatter_url = settings.java
      and settings.java.format
      and settings.java.format.settings
      and settings.java.format.settings.url
  if formatter_url and not formatter_url:match("^/") then
    settings.java.format.settings.url = root_dir .. "/" .. formatter_url
  end

  local config = {
    cmd = cmd,
    root_dir = root_dir,
    on_attach = on_attach,
    capabilities = capabilities,

    settings = settings,

    init_options = {
      bundles = bundles,
    },
  }

  jdtls.start_or_attach(config)
end

return M
