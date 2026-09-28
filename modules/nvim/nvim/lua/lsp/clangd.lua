return {
  setup = function(opts)
    vim.lsp.config('clangd', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=never',
        -- let clangd ask the cross compiler for its system headers (newlib etc.)
        '--query-driver=/nix/store/*/bin/arm-none-eabi-*',
      },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
      root_markers = {
        'compile_commands.json',
        '.clangd',
        '.git',
      },
    })

    vim.lsp.enable('clangd')
  end,
}
