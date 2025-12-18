return {
  setup = function()
    -- Completion
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      preselect = cmp.PreselectMode.Item,
      completion = {
        completeopt = "menu,menuone",
        autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
      },
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),

        -- Navigation
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),

        ["<C-y>"] = cmp.mapping.confirm({ select = false }),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.abort()
          end
          fallback()
        end, { "i", "s" }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.abort()
          end
          fallback()
        end, { "i", "s" }),
        ["<S-Tab>"] = function() end,
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "buffer" },
        { name = "luasnip" },
      }),
    })
  end
}
