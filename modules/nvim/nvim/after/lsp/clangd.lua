return {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=never',
    -- let clangd ask the cross compiler for its system headers (newlib etc.)
    '--query-driver=/nix/store/*/bin/arm-none-eabi-*',
  },
}
