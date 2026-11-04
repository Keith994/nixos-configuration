local analyzers_path = vim.fn.stdpath "data" .. "/mason/packages/sonarlint-language-server/extension/analyzers/"

local sonarlint_ft = {
  "c",
  "cpp",
  "css",
  "docker",
  "go",
  "html",
  "java",
  "javascript",
  "javascriptreact",
  "php",
  "python",
  "typescript",
  "typescriptreact",
  "xml",
  "yaml.docker-compose",
}

---@type LazySpec
return {
  "https://gitlab.com/schrieveslaach/sonarlint.nvim",
  ft = sonarlint_ft,
  enabled = false,
  specs = {
    {
      "neovim/nvim-lspconfig",
      optional = true,
      opts = function(_, opts)
        -- 追加而不是 extend_tbl：后者对数组按下标覆盖，会冲掉别的 lang 文件的项。
        -- 详见 lang/java.lua 的注释。（这个 spec 目前 enabled = false，
        -- 但下面 mason-tool-installer 那个块已经是正确写法，两边保持一致。）
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
          "sonarlint-language-server",
        })
        return opts
      end,
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      optional = true,
      opts = function(_, opts)
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "sonarlint-language-server" })
      end,
    },
  },
  opts = {
    server = {
      cmd = {
        "sonarlint-language-server",
        "-stdio",
        "-analyzers",
        analyzers_path .. "sonargo.jar",
        analyzers_path .. "sonarhtml.jar",
        analyzers_path .. "sonariac.jar",
        analyzers_path .. "sonarjava.jar",
        analyzers_path .. "sonarjavasymbolicexecution.jar",
        analyzers_path .. "sonarjs.jar",
        analyzers_path .. "sonarphp.jar",
        analyzers_path .. "sonarpython.jar",
        analyzers_path .. "sonarxml.jar",
      },
    },
    filetypes = sonarlint_ft,
  },
}
