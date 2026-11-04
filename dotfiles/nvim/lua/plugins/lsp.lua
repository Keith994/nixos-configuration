local function keymaps(event)
  local map = function(keys, func, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
  end

  local picker = require("snacks.picker")

  map("gy", vim.lsp.buf.hover, "Hover Symbol Details")
  map("ga", vim.lsp.buf.code_action, "Code Action")
  map("gA", vim.lsp.codelens.run, "CodeLens Run")
  map("gd", picker.lsp_definitions, "Defnition")
  map("<A-.>", picker.lsp_definitions, "Defnition", {"i", "n"})
  map("gD", picker.lsp_type_definitions, "Type Defnition")
  map("gr", picker.lsp_references, "Refereences Of Current Symbol")
  map("<A-?>", picker.lsp_references, "Refereences Of Current Symbol", {"i", "n"})
  map("gR", vim.lsp.buf.rename, "Rename Current Symbol")
  map("gl", vim.diagnostic.open_float, "Hover Diagnostic")
  map("gI", picker.lsp_implementations, "Implementations")
  map("<c-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
  map("<Leader>cl", picker.lsp_config, "Server Info")
  map("<Leader>ca", vim.lsp.buf.code_action, "Code Action")
  -- map("<Leader>cc", vim.lsp.codelens.run, "CodeLens Run")
  -- map("<Leader>cC", vim.lsp.codelens.refresh, "Refresh CodeLens")
  map("<Leader>cR", vim.lsp.buf.rename, "Rename Current Symbol")
  map("<Leader>cr", picker.lsp_references, "Refereences Of Current Symbol")

  map("<Leader>cs", picker.lsp_symbols, "Symbols")
  map("<Leader>cS", picker.lsp_workspace_symbols, "Workspace Symbols")
  map("<Leader>cd", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", "Document Diagnostics")
  map("<Leader>cD", "<Cmd>Trouble diagnostics toggle<CR>", "Workspace Diagnostics")

  map("<C-F5>", function() -- C+F5
    require("dap").continue()
  end, "Debug: Start/Continue")
  map("<F29>", function() -- C+F5
    require("dap").continue()
  end, "Debug: Start/Continue")
  map("<F5>", function()
    require("dap").continue()
  end, "Debug: Start/Continue")
  map("<F17>", function() -- S-F5
    require("dap").terminate()
  end, "Debug: Terminate")
  map("<S-F5>", function() -- S-F5
    require("dap").terminate()
  end, "Debug: Terminate")
  map("<F6>", function()
    require("dap").pause()
  end, "Debug: Pause")
  map("<F10>", function()
    require("dap").step_over()
  end, "Debug: Step Over")
  map("<F11>", function()
    require("dap").step_into()
  end, "Debug: Step Into")
  map("<S-F11>", function()
    require("dap").step_out()
  end, "Debug: Step Out")
  map("<F23>", function()
    require("dap").step_out()
  end, "Debug: Step Out")
  -- C-S-F9<F45>
  map("<C-S-F9>", require("dap").clear_breakpoints, "Clear Breakpoints")
  map("<F45>", require("dap").clear_breakpoints, "Clear Breakpoints")
  -- C-f10
  map("<C-F10>", require("dap").run_to_cursor, "Run To Cursor")
  map("<F34>", require("dap").run_to_cursor, "Run To Cursor")
  map("<F9>", require("dap").toggle_breakpoint, "Toggle Breakpoint")
  -- S-F9
  -- map("<S-F9>",
  --   function()
  --     vim.ui.input({ prompt = "Condition: " }, function(condition)
  --       if condition then require("dap").set_breakpoint(condition) end
  --     end)
  --   end, "Toggle Breakpoint")
  map("<F21>",
    function()
      vim.ui.input({ prompt = "Condition: " }, function(condition)
        if condition then require("dap").set_breakpoint(condition) end
      end)
    end, "Toggle Breakpoint")
end

return {
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    cmd = { "Mason", "MasonInstall", "LspStart" },
    event = "BufReadPre",
    dependencies = {
      "mfussenegger/nvim-dap",
      {
        "mason-org/mason.nvim",
        cmd = {
          "MasonInstall",
          "MasonUninstall",
          "MasonUninstallAll",
          "MasonLog",
        },
        build = ":MasonUpdate",
        opts = {},
        dependencies = {
          { "mason-org/mason-lspconfig.nvim", config = function() end },
        },
      },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    opts = function()
      local icons = require("util.icons")

      ---@class PluginLspOpts
      local ret = {
        ---@type vim.diagnostic.Opts
        diagnostics = {
          underline = { severity = vim.diagnostic.severity.ERROR },
          severity_sort = true,
          virtual_text = {
            spacing = 1,
            source = "if_many",
            prefix = "●",
            format = function(diagnostic)
              local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
                [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
                [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
                [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
              }
              return diagnostic_message[diagnostic.severity]
            end,
          },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
              [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
              [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
              [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
            },
          },
        },
        ensure_installed = {},
        inlay_hints = {
          enabled = false,
        },
        codelens = {
          enabled = false,
        },
        capabilities = {
          workspace = {
            fileOperations = {
              didRename = true,
              willRename = true,
            },
          },
        },
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        servers = {},
        setup = {},
      }
      return ret
    end,
    ---@param opts PluginLspOpts
    config = function(_, opts)
      vim.api.nvim_create_autocmd("LspProgress", {
        ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
        callback = function(ev)
          local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          vim.notify(vim.lsp.status(), "info", {
            id = "lsp_progress",
            title = "LSP Progress",
            opts = function(notif)
              notif.icon = ev.data.params.value.kind == "end" and " "
                  or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
            end,
          })
        end,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          keymaps(event)

          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
              end,
            })
          end
        end,
      })
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
      local ensure_installed = opts.ensure_installed
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      -- mason-lspconfig **v2**（lazy-lock 里的 77e06f7）删掉了 v1 的 handlers 选项：
      -- 它的 setup() 只认 ensure_installed 和 automatic_enable，压根不读 handlers。
      -- 所以这里以前传的那个 handler 函数从来没被调用过一次，连带 opts.servers 里
      -- 各 lang 文件写的 per-server 设置至今也是死的（gopls.lua 甚至没有任何
      -- vim.lsp.enable，等于 gopls 一直没起来）。
      -- v2 的等价写法是 vim.lsp.config(name, server) + vim.lsp.enable(name)：
      -- lang/{rust,nix,nushell}.lua 已经自己调 enable 了。要不要把那批 servers 设置
      -- 接回来是**另一件事**（会同时改变 gopls / lua_ls / basedpyright / ruff /
      -- jsonls / nil_ls 的行为），别混进修 jdtls 的这次改动里。
      require("mason-lspconfig").setup({
        -- 刻意留空：mason-lspconfig 的 ensure_installed 要的是 **lspconfig server 名**，
        -- 而 opts.ensure_installed 里是 **mason 包名**（lang/json.lua 那种两套都写的更混），
        -- 命名空间不一样，把同一份列表喂进来只会刷一堆 unknown package。
        -- 安装这件事统一交给上面的 mason-tool-installer。
        ensure_installed = {},
        -- jdtls 由 nvim-jdtls 用自定义 cmd 起（见 lang/java.lua：要往里塞 -Xmx、
        -- lombok agent、debug bundles），不能让 mason-lspconfig 再 vim.lsp.enable("jdtls")
        -- 一次 —— 否则打开一个 .java 会同时起两个 jdtls client 互相踩。
        -- mason 只是 jdtls 的兜底来源（主路径是 nixpkgs，见 lang/java.lua 的 jdtls_home）。
        automatic_enable = { exclude = { "jdtls" } },
      })
    end,
  },
}
