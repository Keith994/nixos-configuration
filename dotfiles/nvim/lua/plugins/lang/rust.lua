return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      local ret = {
        ensure_installed = { "taplo", "codelldb" },
      }
      return utils.extend_tbl(opts, ret)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed, { "rust" })
      end
    end,
  },
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      if not opts.adapters then
        opts.adapters = {}
      end
      local avail, rustaceanvim = pcall(require, "rustaceanvim.neotest")
      if avail then
        table.insert(opts.adapters, rustaceanvim)
      end
    end,
  },

  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    ft = "rust",
    opts = function()
      local adapter
      local codelldb_installed = pcall(function()
        return require("mason-registry").get_package("codelldb")
      end)
      local cfg = require("rustaceanvim.config")
      if codelldb_installed then
        local codelldb_path = vim.fn.exepath("codelldb")
        local this_os = vim.uv.os_uname().sysname

        local liblldb_path = vim.fn.expand("$MASON/share/lldb")
        -- The path in windows is different
        if this_os:find("Windows") then
          liblldb_path = liblldb_path .. "\\bin\\lldb.dll"
        else
          -- The liblldb extension is .so for linux and .dylib for macOS
          liblldb_path = liblldb_path .. "/lib/liblldb" .. (this_os == "Linux" and ".so" or ".dylib")
        end
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path)
      else
        adapter = cfg.get_codelldb_adapter()
      end

      local settings = {
        ["rust-analyzer"] = {
          files = {
            excludeDirs = {
              ".direnv",
              ".git",
              "target",
            },
          },
          check = {
            command = "clippy",
            extraArgs = {
              "--no-deps",
            },
          },
          procMacro = {
            enable = true,
          },
        },
      }

      local server = {
        settings = function(project_root, default_settings)
          local merge_table = utils.extend_tbl(default_settings or {}, settings)
          local ra = require("rustaceanvim.config.server")
          return ra.load_rust_analyzer_settings(project_root, {
            settings_file_pattern = "rust-analyzer.json",
            default_settings = merge_table,
          })
        end,
        on_attach = function(client, buf)
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = buf, desc = "LSP: " .. desc })
          end
          map("<Leader>ce", function()
            vim.cmd.RustLsp("expandMacro")
          end, "Rust Expand Macro")
          map("<F5>", function()
            vim.cmd("RustLsp debuggables")
          end, "Debug: Start")
        end,
      }

      return {
        server = server,
        dap = { adapter = adapter, load_rust_types = true },
        tools = { enable_clippy = true },
      }
    end,
    config = function(_, opts)
      vim.lsp.enable("rust-analyzer")
      vim.g.rustaceanvim = utils.extend_tbl(opts, vim.g.rustaceanvim)
    end,
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
      },
    },
  },
}
