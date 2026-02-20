return {
  setup = function(opts)
    vim.lsp.config('rust_analyzer', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      cmd = { 'rust-analyzer' },
      filetypes = { 'rust' },
      root_markers = {
        'Cargo.toml',
        'rust-project.json',
        '.git',
      },
      settings = {
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = true,
          },
          checkOnSave = true,
          check = {
            command = 'clippy',
          },
          procMacro = {
            enable = true,
          },
        },
      },
    })

    vim.lsp.enable('rust_analyzer')
  end,
}
