-- ~/git/configs/nvim/lua/jdtls/jdtls_setup.lua
local M = {}

function M.setup()
  local ok, jdtls = pcall(require, "jdtls")
  if not ok then
    vim.notify("[jdtls] Plugin 'nvim-jdtls' nicht gefunden", vim.log.levels.ERROR)
    return
  end

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

  local debug_dir = os.getenv("JAVA_DEBUG_SERVER_DIR")
  local test_dir = os.getenv("JAVA_TEST_SERVER_DIR")

  -- Debug
  for _, jar in ipairs(vim.fn.glob(debug_dir .. "/com.microsoft.java.debug.plugin-*.jar", 1, 1)) do
    table.insert(bundles, jar)
  end

  -- Test (nur plugin)
  for _, jar in ipairs(vim.fn.glob(test_dir .. "/com.microsoft.java.test.plugin-*.jar", 1, 1)) do
    table.insert(bundles, jar)
  end

  if #bundles == 0 then
    vim.notify("[jdtls] Warnung: keine Debug/Test-Bundles gefunden", vim.log.levels.WARN)
  end

  -- Lombok-Agent
  local lombok_jar = os.getenv("LOMBOK_JAR")

  -- FIXME: workaround for incompatible versions jdtls 1.52 and vscode-java-test
  -- statt "jdtls" / "jdt-language-server" aus PATH:
  local jdtls_bin =
  "/nix/store/wkyckfdj74z7gzk43fifla50vcyx3540-jdt-language-server-1.46.1/bin/jdtls" -- pinned due to asm range mismatch with vscode-java-test
  local cmd = { jdtls_bin, "--data", workspace_dir }

  -- Executable für jdtls herausfinden (jdtls oder jdt-language-server)
  -- local cmd
  -- if vim.fn.executable("jdtls") == 1 then
  --   cmd = { "jdtls", "--data", workspace_dir }
  -- elseif vim.fn.executable("jdt-language-server") == 1 then
  --   cmd = { "jdt-language-server", "-data", workspace_dir }
  -- else
  --   vim.notify("[jdtls] Kein 'jdtls' oder 'jdt-language-server' im PATH gefunden", vim.log.levels.ERROR)
  --   return
  -- end

  if lombok_jar and lombok_jar ~= "" then
    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
  end
  table.insert(cmd, "--jvm-arg=-Xmx2g")

  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  local function on_attach(client, bufnr)
    -- Standard-LSP-Keymaps
    local opts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>cc", "<cmd>JdtCompile<CR>", opts)

    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>de", vim.diagnostic.open_float, opts)

    -- Java-spezifische Test-Keymaps (nvim-jdtls)
    vim.keymap.set("n", "<leader>tn", jdtls.test_nearest_method, { buffer = bufnr, desc = "Java: Test nearest" })
    vim.keymap.set("n", "<leader>tN", jdtls.test_class, { buffer = bufnr, desc = "Java: Test class" })
    --
    -- vim.keymap.set("n", "<leader>tA", require("jdtls.jdtls_setup").test_all_test_classes, vim.tbl_extend("force", opts, { desc = "Java: All *Test.java in project" }))
    -- vim.keymap.set("n", "<leader>tp", require("jdtls.jdtls_setup").test_current_package, vim.tbl_extend("force", opts, { desc = "Java: Tests in current package" }))

    local dap_ok, dap = pcall(require, "dap")
    if dap_ok then
      jdtls.setup_dap({ hotcodereplace = "auto" })
      if jdtls.setup_dap_main_class_config then
        jdtls.setup_dap_main_class_config()
      end
      require("dap.ext.vscode").load_launchjs(vim.fn.getcwd() .. "/launch.json", {
        java = { "java" }, -- mappe VSCode "type": "java" auf dap.adapters.java
      })
    end
  end

  local config = {
    cmd = cmd,
    root_dir = root_dir,
    capabilities = capabilities,

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
          updateBuildConfiguration = "interactive", -- keine nervigen Popups
        },
        project = {
          importHint = false,
        },
        import = {
          maven = { enabled = true, downloadSources = true },
          gradle = { enabled = true, wrapper = { enabled = true } },
        },
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
        implementationsCodeLens = { enabled = true },
        referencesCodeLens = { enabled = true },
        references = { enabled = true, includeDecompiledSources = true },
        format = { enabled = true },
      },
    },

    init_options = {
      -- workspace = workspace_dir,
      bundles = bundles,
    },

    on_attach = on_attach,
  }

  jdtls.start_or_attach(config)
end

local function find_all_test_files(root_dir)
  -- Standard-Maven-Test-Root
  local test_root = root_dir .. "/src/test/java"
  if vim.fn.isdirectory(test_root) == 0 then
    return {}
  end

  -- rekursiv alle *Test.java finden
  -- 2. Argument: 1 = "liste", 3. Argument: 1 = "als Lua-Tabelle"
  local pattern = test_root .. "/**/*Test.java"
  local files = vim.fn.glob(pattern, 1, 1)

  -- optional: Du kannst hier debuggen, was er gefunden hat
  vim.notify("Gefundene Test-Dateien:\n" .. vim.inspect(files), vim.log.levels.INFO)

  return files
end

-- alle *Test.java im Projekt finden und jeweils jdtls.test_class() aufrufen
function M.test_all_test_classes()
  local jdtls = require("jdtls")

  -- aktiven jdtls-Client holen (wir gehen davon aus: genau einer)
  local clients = vim.lsp.get_clients({ name = "jdtls" })
  if #clients == 0 then
    vim.notify("[jdtls] Kein aktiver jdtls-Client gefunden", vim.log.levels.WARN)
    return
  end

  local root_dir = clients[1].config.root_dir
  if not root_dir or root_dir == "" then
    vim.notify("[jdtls] root_dir nicht gesetzt", vim.log.levels.WARN)
    return
  end

  -- alle *Test.java unterhalb des Projekts suchen
  local test_files = find_all_test_files(root_dir)
  vim.notify(vim.inspect(test_files), vim.log.levels.INFO)

  for _, f in ipairs(test_files) do
    print("[jdtls] file found: " .. f)
  end

  if #test_files == 0 then
    vim.notify("[jdtls] Keine *Test.java unter src/test/java gefunden", vim.log.levels.INFO)
    return
  end

  vim.notify("[jdtls] Starte Tests für " .. #test_files .. " Test-Klassen", vim.log.levels.INFO)

  for _, file in ipairs(test_files) do
    -- Datei laden (oder in bestehendem Fenster öffnen)
    vim.notify("[jdtls] Open file: " .. file, vim.log.levels.WARN)
    vim.cmd("edit " .. vim.fn.fnameescape(file))
    -- kurze Pause wäre optional, meist geht's ohne
    jdtls.test_class()
  end
end

-- alle Tests im "Package" des aktuellen Files
function M.test_current_package()
  local jdtls = require("jdtls")

  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("[jdtls] Kein aktuelles File", vim.log.levels.WARN)
    return
  end

  local dir = vim.fn.fnamemodify(file, ":h")

  -- wenn wir unter src/test/java sind, nehmen wir ab da alles
  local idx = dir:find("/src/test/java/", 1, true)
  local search_dir = dir
  if idx then
    search_dir = dir:sub(1 + idx + #"/src/test/java/")
    search_dir = vim.fn.fnamemodify(file:sub(1, idx + #"/src/test/java/" - 1) .. search_dir, ":p")
  end

  -- sicherheitshalber: falls das irgendwie schief geht, nimm einfach das aktuelle Verzeichnis
  if not search_dir or search_dir == "" then
    search_dir = dir
  end

  local clients = vim.lsp.get_clients({ name = "jdtls" })
  if #clients == 0 then
    vim.notify("[jdtls] Kein aktiver jdtls-Client gefunden", vim.log.levels.WARN)
    return
  end

  -- Tests unterhalb dieses Verzeichnisses finden
  local test_files = vim.fs.find(function(name, path)
    return name:match("Test%.java$") ~= nil
  end, {
    path = search_dir,
    type = "file",
  })

  if #test_files == 0 then
    vim.notify("[jdtls] Keine *Test.java im aktuellen Package-Verzeichnis gefunden", vim.log.levels.INFO)
    return
  end

  vim.notify("[jdtls] Starte Tests für " .. #test_files .. " Test-Klassen im aktuellen Package", vim.log.levels.INFO)

  for _, f in ipairs(test_files) do
    vim.cmd("edit " .. vim.fn.fnameescape(f))
    jdtls.test_class()
  end
end

return M
