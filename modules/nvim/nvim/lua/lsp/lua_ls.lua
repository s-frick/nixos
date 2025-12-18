return {
  setup = function(opts)
    -- Lua (Neovim)
    vim.lsp.config('lua_ls', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file("", true),
          },
          completion = {
            callSnippet = "Replace",
          },
          telemetry = { enable = false },
        },
      },
    })
    vim.lsp.enable('lua_ls')
  end
}
