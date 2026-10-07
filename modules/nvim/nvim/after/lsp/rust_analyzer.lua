return {
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
}
