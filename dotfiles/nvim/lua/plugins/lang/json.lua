return {
  {
    "b0o/schemastore.nvim",
    lazy = true,
    specs = {
      {
        "neovim/nvim-lspconfig",
        optional = true,
        opts = function(_, opts)
          -- make sure mason installs the server
          return utils.extend_tbl(opts, {
            ensure_installed = { "jsonls", "json-lsp", "prettierd" },
            servers = {
              jsonls = {
                on_new_config = function(config)
                  if not config.settings.json.schemas then
                    config.settings.json.schemas = {}
                  end
                  vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
                end,
                settings = { json = { validate = { enable = true } } },
              },
            },
          })
        end,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        json = { "prettierd", lsp_format = "last" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "json", "jsonc" })
      end
    end,
  },
}
