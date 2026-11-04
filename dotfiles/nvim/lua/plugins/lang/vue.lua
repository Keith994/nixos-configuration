-- Vue SFC + TypeScript（iot-edge-ui 那类 vite4 + vue3 + pnpm workspace 工程：
-- 660 个 .vue、558 个 .ts，只有 .prettierrc、没有 eslint 配置）。
--
-- 为什么是三个服务器而不是一个：
--   * vue_ls  —— 管 .vue 的 template / style 段。注意它**从 v3 起不再 takeover**，
--                 <script lang="ts"> 的类型判断不归它做了；
--   * vtsls   —— 管 .ts / .js，并且要加载 @vue/typescript-plugin 才能接住
--                 vue_ls 转发过来的 tsserver/request（这是 v3 之后 .vue 里类型唯一的来源）；
--   * tailwindcss-language-server —— class 补全（工程用 tailwind 3.4 + daisyui）。
--
-- 插件位置写死成 mason 的包目录：@vue/typescript-plugin 是 mason 装
-- vue-language-server 时**顺带**带下来的（同目录下的 @vue/typescript-plugin），
-- 工程的 node_modules 里没有它，所以纯改工程依赖拿不到。
-- location 要指 `@vue/language-server` 目录而不是 `@vue/typescript-plugin` 目录 ——
-- vtsls 从 location 往上做 node 模块解析，按 name 找到插件本体；
-- 指错位置的表现是「.vue 里类型全丢，且任何地方都不报错」。
local vue_ls_path = vim.fn.stdpath("data")
    .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      -- ensure_installed 必须**追加**（mason 包名）：写成 utils.extend_tbl 的
      -- 返回值会把别的 lang 文件已经塞进去的整张表换掉，见 lang/java.lua 的注释。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
        "vtsls",
        "vue-language-server",
        "tailwindcss-language-server",
        -- 工程的格式化入口就是 .prettierrc，但 package.json 里没装 prettier，
        -- 所以用 mason 的 prettierd（常驻进程，比每次起 prettier 快）
        "prettierd",
      })

      -- mason-lspconfig v2 不读 opts.servers，per-server 设置只能走
      -- vim.lsp.config + vim.lsp.enable（见 plugins/lsp.lua 里那段注释）。
      vim.lsp.config("vtsls", {
        -- 多挂一个 vue：vtsls 只对自己 filetype 里的 buffer 建 TS 语言服务，
        -- .vue 不在这里面的话，vue_ls 转来的请求会被直接丢掉
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = vue_ls_path,
                  languages = { "vue" },
                  configNamespace = "typescript",
                },
              },
            },
          },
        },
      })
      vim.lsp.enable("vtsls", true)
      vim.lsp.enable("vue_ls", true)
      -- tailwindcss 的默认 filetypes 里已经有 vue，root_dir 也认根目录的
      -- tailwind.config.js（工程根目录那份），所以不用再补设置
      vim.lsp.enable("tailwindcss", true)

      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        -- .prettierrc: trailingComma=none、printWidth=120，prettierd 会自己读到
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        vue = { "prettierd" },
        css = { "prettierd" },
        scss = { "prettierd" },
        less = { "prettierd" },
        html = { "prettierd" },
        yaml = { "prettierd" },
        -- json 不在这里写：lang/json.lua 已经给了 { "prettierd", lsp_format = "last" }
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        -- template 段要 vue parser 才对得上标签高亮/折叠，css/scss 是 scoped style 与
        -- 单独样式文件（工程里 16 个 .scss）
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "vue", "css", "scss" })
      end
    end,
  },
}
