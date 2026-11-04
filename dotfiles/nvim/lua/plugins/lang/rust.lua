return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      -- ensure_installed 必须用 list_insert_unique **追加**，不能塞进 ret 再
      -- utils.extend_tbl：后者底层是 vim.tbl_deep_extend("force")，对数组是
      -- **按下标覆盖**，会把别的 lang 文件已经塞进去的项冲掉。详见 lang/java.lua 的注释。
      --
      -- 这里刻意**不再列 codelldb**：它在 mason registry 里是 pkg:github/vadimcn/vscode-lldb，
      -- 本机直连 GitHub Releases 超时（实测 25s 收 0 字节），mason.log 里它失败了 133 次，
      -- 而且每次启动 nvim 都会重试一遍、拖慢启动。要恢复 Rust 调试得先让 GitHub 可达
      -- （给 nvim 配 https_proxy 走 clash 的 10800），或者改用 nixpkgs 的
      -- vscode-extensions.vadimcn.vscode-lldb —— 别指望 mason 自己重试成功。
      -- taplo（Cargo.toml 的 LSP）留着，它的源不是 GitHub Releases。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, { "taplo" })
      return opts
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
      -- 以前这里写的是 `local codelldb_installed = pcall(function() return
      -- require("mason-registry").get_package("codelldb") end)`，有两个问题：
      --   1. get_package() 只查 registry 里**有没有这个包名**，不查装没装 ——
      --      codelldb 没装成功时它也恒为真；
      --   2. pcall 返回 (ok, value)，只接一个变量拿到的是 ok，
      --      所以就算里面 return false 也照样是真。
      -- 两者叠加的结果是把空字符串的 codelldb_path 喂给 get_codelldb_adapter()，
      -- Rust 调试静默坏掉、报不出原因。改成真的问 is_installed()，
      -- 并把 package 对象留下来 —— 下面要用它的 get_install_path() 定位 liblldb。
      local codelldb_pkg = nil
      pcall(function()
        local p = require("mason-registry").get_package("codelldb")
        if p:is_installed() then
          codelldb_pkg = p
        end
      end)
      local cfg = require("rustaceanvim.config")
      if codelldb_pkg then
        local codelldb_path = vim.fn.exepath("codelldb")
        local this_os = vim.uv.os_uname().sysname

        -- liblldb 以前写的是 expand("$MASON/share/lldb/lib/liblldb.so")，**两处都错**：
        --   1. $MASON 通常没设（见 util/init.lua 的 M.mason_root 注释），
        --      expand 把它替换成空 → "/share/lldb/..."；
        --   2. 就算根目录对了也不对：mason 装的 codelldb 里 liblldb 实际在
        --      packages/codelldb/extension/lldb/lib/liblldb.so（实测），
        --      share/ 底下**根本没有 lldb 目录**（只有 java-debug-adapter、java-test、
        --      jdtls、mason-schemas、vscode-spring-boot-tools）。
        -- 所以直接从 package 的 get_install_path() 拼：不猜布局、不依赖环境变量。
        local lldb_root = codelldb_pkg:get_install_path() .. "/extension/lldb"
        local liblldb_path
        -- The path in windows is different
        if this_os:find("Windows") then
          liblldb_path = lldb_root .. "\\bin\\lldb.dll"
        else
          -- The liblldb extension is .so for linux and .dylib for macOS
          liblldb_path = lldb_root .. "/lib/liblldb" .. (this_os == "Linux" and ".so" or ".dylib")
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
