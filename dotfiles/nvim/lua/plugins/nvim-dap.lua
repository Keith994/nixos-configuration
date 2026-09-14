return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      -- virtual text for the debugger
      {
        "theHamsta/nvim-dap-virtual-text",
        conidtion = vim.g.enable_dap_virtual,
        opts = {},
      },
    },

    -- stylua: ignore
    keys = {
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Condition: " }, function(condition)
            if condition then require("dap").set_breakpoint(condition) end
          end)
        end,
        desc = "Breakpoint Condition"
      },
      { "<leader>db", function() require("dap").toggle_breakpoint() end,             desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                      desc = "Run/Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end,                 desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end,                         desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end,                     desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end,                          desc = "Down" },
      { "<leader>dk", function() require("dap").up() end,                            desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end,                      desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end,                      desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end,                     desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end,                         desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end,                   desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end,                       desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end,                     desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end,              desc = "Widgets" },
    },

    config = function()
      -- load mason-nvim-dap here, after all adapters have been setup
      if utils.is_available("mason-nvim-dap.nvim") then
        require("mason-nvim-dap").setup(utils.opts("mason-nvim-dap.nvim"))
      end

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(require("util.icons").dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- setup dap config by VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
    end,
  },

  -- fancy UI for the debugger
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = { "<leader>du", "<leader>dv" },
    opts = function(opts)
      local map = function(keys, func, desc, mode)
        mode = mode or "n"
        vim.keymap.set(mode, keys, func, { desc = desc })
      end

      local dapui = require("dapui")
      local windows = require("dapui.windows")
      local toggleUI = function(num)
        if windows.layouts[num]:is_open() then
          dapui.close({ layout = num })
        else
          dapui.open({ layout = num })
        end
      end
      map("<Leader>du", function()
        toggleUI(3)
      end, "Toggle DAP Repl And Watch UI")
      map("<Leader>dv", function()
        toggleUI(4)
      end, "Toggle DAP Right Console UI")
      map("<Leader>dh", function()
        toggleUI(5)
      end, "Toggle DAP Bottom Console UI")

      local utils = utils
      return utils.extend_tbl({
        layouts = {
          {
            elements = {
              {
                id = "scopes",
                size = 0.35,
              },
              {
                id = "watches",
                size = 0.35,
              },
              {
                id = "breakpoints",
                size = 0.15,
              },
              {
                id = "stacks",
                size = 0.15,
              },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              {
                id = "repl",
                size = 0.5,
              },
              {
                id = "console",
                size = 0.5,
              },
            },
            position = "bottom",
            size = 10,
          },
          {
            elements = {
              {
                id = "watches",
                size = 0.5,
              },
              {
                id = "repl",
                size = 0.5,
              },
            },
            position = "bottom",
            size = 12,
          },
          {
            elements = {
              {
                id = "console",
                size = 1,
              },
            },
            position = "right",
            size = 50,
          },
          {
            elements = {
              {
                id = "console",
                size = 1,
              },
            },
            position = "bottom",
            size = 10,
          },
        },
      })
    end,
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dap.listeners.after.event_initialized.dapui_config = function()
        dapui.open({ layout = 3 })
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        print("Dap终止")
        dapui.close({ layout = 3 })
      end
      dap.listeners.before.event_exited.dapui_config = function() end

      dapui.setup(opts)
    end,
  },

  -- mason.nvim integration
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    },
    -- mason-nvim-dap is loaded when nvim-dap loads
    config = function() end,
  },
}
