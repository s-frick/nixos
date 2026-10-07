return {
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
}
