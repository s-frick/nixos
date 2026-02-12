return {
  setup = function(opts)
    -- Kotlin Language Server (optimized for KMP projects)
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
          },
          -- Performance optimizations
          indexing = {
            enabled = true,
          },
          completion = {
            snippets = {
              enabled = true
            }
          },
          -- Reduce diagnostics frequency to lower CPU/memory usage
          diagnostics = {
            debounce = 500,  -- Wait 500ms before running diagnostics
          },
          -- Inlay hints can be memory-intensive, consider disabling if needed
          inlayHints = {
            typeHints = true,
            parameterHints = true,
            chainingHints = false,  -- Disabled for performance
          }
        }
      }
    })
    vim.lsp.enable('kotlin_language_server')
  end
}
