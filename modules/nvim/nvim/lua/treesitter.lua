return {
  setup = function()
    -- Treesitter: Parser in ein beschreibbares Verzeichnis legen (nicht im Nix-Store)
    local parser_path = vim.fn.stdpath("data") .. "/treesitter-parsers"
    vim.fn.mkdir(parser_path, "p")
    vim.opt.runtimepath:append(parser_path) -- RTP, damit Neovim dort .so findet

    require("nvim-treesitter.install").prefer_git = false
    require("nvim-treesitter.install").compilers = {}  -- we never compile
    require("nvim-treesitter.configs").setup({
      parser_install_dir = parser_path,
      ensure_installed = {}, -- controlled by nixos
      auto_install = false, -- controlled by nixos
      highlight = { enable = true },
      indent = { enable = true },
      modules = {},
      ignore_install = {},
      sync_install = false,
    })
  end
}
