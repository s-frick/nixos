return {
  setup = function(opts)
    -- Kotlin Language Server
    vim.lsp.config('kotlin_language_server', {
      capabilities = opts.capabilities,
      on_attach = opts.on_attach,
      cmd = { 'kotlin-language-server' },
      filetypes = { 'kotlin' },
      root_markers = {
        'settings.gradle',
        'settings.gradle.kts',
        'build.gradle',
        'build.gradle.kts',
        'pom.xml',
      },
      settings = {
        kotlin = {
          compiler = {
            jvm = {
              target = "17"
            }
          }
        }
      }
    })
    vim.lsp.enable('kotlin_language_server')
  end
}
