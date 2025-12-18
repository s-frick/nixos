local util = require('lspconfig').util
return {
  setup = function(opts)
    vim.lsp.config('ts_ls', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      cmd = { "typescript-language-server", "--stdio" },
      -- root_dir = util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
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
    vim.lsp.enable('ts_ls')
  end
}
