local function selene_configured(path)
  return #vim.fs.find("selene.toml", { path = path, upward = true, type = "file" }) > 0
end
local list_insert_unique = utils.list_insert_unique
local is_aarch64 = vim.loop.os_uname().machine == "aarch64"
return {

  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      local ret = {
        servers = {
          lua_ls = {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim", "utils" }, -- Important!  Tells lua_ls that 'vim' is a global variable.
                },
                workspace = {
                  checkThirdParty = false,
                },
                codeLens = {
                  enable = true,
                },
                completion = {
                  callSnippet = "Replace",
                },
                doc = {
                  privateName = { "^_" },
                },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          },
        },
      }
      -- ensure_installed 必须**追加**，不能留在 ret 里交给 extend_tbl：
      -- 后者底层是 vim.tbl_deep_extend("force")，对数组是按下标覆盖，
      -- 会冲掉别的 lang 文件已经塞进去的项。详见 lang/java.lua 的注释。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
        "lua_ls",
        "lua-language-server",
        "stylua",
        "selene",
      })
      return utils.extend_tbl(opts, ret)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = list_insert_unique(opts.ensure_installed, { "lua", "luap" })
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua", lsp_format = "last" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      if not is_aarch64 then
        opts.linters_by_ft = {
          lua = { "selene" },
        }
        opts.linters = opts.linters or {}
        opts.linters.selene = {
          condition = function(ctx)
            return selene_configured(ctx.filename)
          end,
        }
      end
    end,
  },
}
