return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      local ret = {
        servers = {
          basedpyright = {
            before_init = function(_, c)
              if not c.settings then
                c.settings = {}
              end
              if not c.settings.python then
                c.settings.python = {}
              end
              c.settings.python.pythonPath = vim.fn.exepath("python")
            end,
            settings = {
              basedpyright = {
                analysis = {
                  typeCheckingMode = "basic",
                  autoImportCompletions = true,
                  diagnosticSeverityOverrides = {
                    reportUnusedImport = "information",
                    reportUnusedFunction = "information",
                    reportUnusedVariable = "information",
                    reportGeneralTypeIssues = "none",
                    reportOptionalMemberAccess = "none",
                    reportOptionalSubscript = "none",
                    reportPrivateImportUsage = "none",
                  },
                },
              },
            },
          },
          ruff = {
            on_attach = function(client)
              client.server_capabilities.hoverProvider = false
            end,
          },
        },
      }
      -- ensure_installed 必须**追加**，不能留在 ret 里交给 extend_tbl：
      -- 后者对数组是按下标覆盖，会冲掉别的 lang 文件已经塞进去的项。
      -- 详见 lang/java.lua 的注释。
      -- basedpyright 走 npm、debugpy 走 pypi，本机都可达；
      -- ruff 在 mason registry 里是 pkg:github/astral-sh/ruff（GitHub Releases，
      -- 本机直连超时），装不上时 conform/nvim-lint 会自己跳过，先留着不删。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
        "basedpyright",
        "debugpy",
        "ruff",
      })
      return utils.extend_tbl(opts, ret)
    end,
  },
  -- python support
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "python", "toml" })
      end
    end,
  },
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    enabled = vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1 or vim.fn.executable("fd-find") == 1,
    opts = function(_, opts)
      utils.mapkey("<leader>cv", "<Cmd>VenvSelect<CR>", "Select VirtualEnv")
      return opts
    end,
    cmd = "VenvSelect",
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    specs = {
      {
        "mfussenegger/nvim-dap-python",
        dependencies = "mfussenegger/nvim-dap",
        ft = "python", -- NOTE: ft: lazy-load on filetype
        config = function(_, opts)
          local path = vim.fn.exepath("python")
          local debugpy = require("mason-registry").get_package("debugpy")
          if debugpy:is_installed() then
            -- 用 get_install_path() 而不是 expand("$MASON/packages/debugpy")：
            -- $MASON 通常没设（mason.nvim 只在安装/卸载时才设它），expand 会把它
            -- 替换成空 → "/packages/debugpy"。详见 util/init.lua 的 M.mason_root 注释。
            -- 本机现在没装 debugpy，所以这条分支走不到 —— 但坑是一样的，一并修掉。
            path = debugpy:get_install_path()
            if vim.fn.has("win32") == 1 then
              path = path .. "/venv/Scripts/python"
            else
              path = path .. "/venv/bin/python"
            end
          end
          require("dap-python").setup(path, opts)
        end,
      },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python", config = function() end },
    opts = function(_, opts)
      if not opts.adapters then
        opts.adapters = {}
      end
      table.insert(opts.adapters, require("neotest-python")(utils.plugin_opts("neotest-python")))
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
    },
  },
}
