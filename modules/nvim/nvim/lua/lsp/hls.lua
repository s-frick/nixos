return {
  setup = function(opts)
    vim.lsp.config('hls', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      cmd = { 'haskell-language-server-wrapper', '--lsp' },
      filetypes = { 'haskell', 'lhaskell', 'cabal' },
      root_markers = {
        'hie.yaml',
        'cabal.project',
        'stack.yaml',
        'package.yaml',
        '.git',
      },
      settings = {
        haskell = {
          formattingProvider = 'ormolu',
        },
      },
    })

    vim.lsp.enable('hls')
  end,
}
