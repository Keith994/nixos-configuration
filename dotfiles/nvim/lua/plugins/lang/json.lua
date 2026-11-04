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
          -- ensure_installed 必须**追加**，不能塞进下面 extend_tbl 的表里：
          -- extend_tbl 底层是 vim.tbl_deep_extend("force")，对数组是按下标覆盖，
          -- 会冲掉别的 lang 文件已经塞进去的项。详见 lang/java.lua 的注释。
          -- 顺带：这里混了两套命名空间 —— "jsonls" 是 lspconfig server 名，
          -- "json-lsp" 才是 mason 包名（两个都写是历史保险），prettierd 是 mason 包名。
          opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
            "jsonls",
            "json-lsp",
            "prettierd",
          })
          return utils.extend_tbl(opts, {
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
