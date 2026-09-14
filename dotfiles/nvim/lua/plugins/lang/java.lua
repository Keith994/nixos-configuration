function get_raw_config(server)
  local ok, ret = pcall(require, "lspconfig.configs." .. server)
  if ok then
    return ret
  end
  return require("lspconfig.server_configurations." .. server)
end

-- This is the same as in lspconfig.configs.jdtls, but avoids
-- needing to require that when this module loads.
local java_filetypes = { "java" }

-- Utility function to extend or override a config table, similar to the way
-- that Plugin.opts works.
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
  if type(custom) == "function" then
    config = custom(config, ...) or config
  elseif custom then
    config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
  end
  return config
end

return {
  -- Add java to treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "java" } },
  },

  -- Ensure java debugger and test packages are installed.
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      -- Simple configuration to attach to remote java debug process
      -- Taken directly from https://github.com/mfussenegger/nvim-dap/wiki/Java
      local dap = require("dap")
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005,
        },
      }
    end,
    dependencies = {
      "mason-org/mason.nvim",
    },
  },

  -- Configure nvim-lspconfig to install the server automatically via mason, but
  -- defer actually starting it to our configuration of nvim-jtdls below.
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      return utils.extend_tbl(opts, {
        -- make sure mason installs the server
        servers = {
          jdtls = {},
        },
        setup = {
          jdtls = function()
            return true -- avoid duplicate servers
          end,
        },
        ensure_installed = { "java-debug-adapter", "java-test", "google-java-format" },
      })
    end,
  },

  -- Set up nvim-jdtls to attach to java files.
  {
    "mfussenegger/nvim-jdtls",
    event = { "BufReadPost *.java" },
    dependencies = { "folke/which-key.nvim", "nvim-lspconfig" },
    opts = function(_, opts)
      local root_dir =
          vim.fs.dirname(vim.fs.find({ ".git", "pom.xml", ".project", "gradlew", "mvnw" }, { upward = true })[1])
      local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
      local workspace_dir = vim.fn.expand("$HOME/.cache/jdtls/" .. project_name)
      local cmd = {
        "/usr/lib/jvm/java-21-openjdk/bin/java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        -- "-Dlog:disable",
        -- "-Djdt.ls.debug=false",
        "-Dlombok.disableConfig=true",
        "-javaagent:" .. vim.fn.expand("$MASON/share/jdtls/lombok.jar"),
        "-Dsun.zip.disableMemoryMapping=true",
        "-Xms100m",          -- 初始堆内存提升
        "-Xmx3g",            -- 最大堆内存提升
        "-XX:+UseG1GC",
        "-XX:GCTimeRatio=4", -- 启用 G1 GC
        "-XX:+ParallelRefProcEnabled",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-XX:+UseStringDeduplication",
        "-XX:MaxGCPauseMillis=200", -- 优化 GC 停顿
        "-XX:MetaspaceSize=512M",   -- Metaspace 初始大小
        "-XX:MaxMetaspaceSize=1G",  -- 限制 Metaspace 上限

        "-XX:+UnlockExperimentalVMOptions",
        "-XX:G1NewSizePercent=20",
        "-XX:InitiatingHeapOccupancyPercent=35",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        vim.fn.expand("$MASON/share/jdtls/plugins/org.eclipse.equinox.launcher.jar"),
        "-configuration",
        vim.fn.expand("$MASON/share/jdtls/config"),
        "-data",
        workspace_dir,
      }

      local bundles = vim.fn.glob(vim.fn.expand("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"),
        false, true)
      -- java-test also depends on java-debug-adapter.
      -- vim.list_extend(bundles, vim.fn.glob("$MASON/share/java-test/*.jar", false, true))
      -- table.insert(bundles,vim.fn.expand("$MASON/share/java-test/com.microsoft.java.test.plugin-0.43.1.jar"))
      local java_test_bundles = vim.split(
        vim.fn.glob("$MASON/share/java-test/*.jar", true, false), "\n")

      local excluded = {
        -- "com.microsoft.java.test.runner-jar-with-dependencies.jar",
        -- "jacocoagent.jar",
        -- "com.microsoft.java.test.plugin-0.43.1.jar",
        -- "junit-platform-commons_1.11.0.jar",
        -- "junit-platform-engine_1.11.0.jar",
        -- "junit-platform-launcher_1.11.0.jar",
        -- "org.apiguardian.api_1.1.2.jar",
        -- "org.opentest4j_1.3.0.jar",
      }
      for _, java_test_jar in ipairs(java_test_bundles) do
        local fname = vim.fn.fnamemodify(java_test_jar, ":t")
        if not vim.tbl_contains(excluded, fname) then
          table.insert(bundles, java_test_jar)
        end
      end
      -- 如果文件是Test.java的，调用super_implementation， 否则调用goto_subjects
      vim.api.nvim_create_user_command("JavaAlt", function()
        local current_file = vim.api.nvim_buf_get_name(0)
        if current_file:match("Test\\.java$") then
          require("jdtls").super_implementation()
        else
          require("jdtls.tests").goto_subjects()
        end
      end, { desc = "Java Alternative Goto" })
      return utils.extend_tbl(opts, {
        root_dir = root_dir,
        cmd = cmd,
        test = true,
        settings = {
          java = {
            index = {
              preload = { "org.springframework.*" },
            },
            autobuild = {
              enabled = false,
            },
            eclipse = { downloadSources = true },
            edit = {
              validateAllOpenBuffersOnChanges = false,
            },
            format = {
              enabled = true,
            },
            progressReports = {
              enabled = false,
            },
            configuration = {
              updateBuildConfiguration = "disabled",
              maven = {
                userSettings = "none",
              },
              runtimes = {
                {
                  name = "JavaSE-11",
                  path = "~/.jenv/jvm/jdk-11.0.9.1+1/",
                  default = true,
                },
                {
                  name = "JavaSE-17",
                  path = "/usr/lib/jvm/java-17-openjdk/",
                },
                {
                  name = "JavaSE-21",
                  path = "/usr/lib/jvm/java-21-openjdk/",
                },
              },
            },
            diagnostic = {
              refreshAfterSave = false,
            },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = false },
            referencesCodeLens = { enabled = false },
            inlayHints = { parameterNames = { enabled = false } },
            signatureHelp = { enabled = true },
            contentProvider = {
              preferred = "fernflower",
            },
            completion = {
              enabled = true,
              favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.junit.Assert.*",
                "org.mockito.Mockito.*",
              },
              filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
                "java.awt.*",
                "jdk.*",
                "sun.*",
              },
              guessMethodArguments = "off",
              maxResults = 30,
              postfix = false,
              matchCase = "off",
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
          },
        },
        init_options = {
          bundles = bundles,
          extendedClientCapabilities = {
            classFileContentsSupport = true,
            resolveAdditionalTextEditsSupport = true,
            progressReportProvider = true,
            generateToStringPromptSupport = true,
            advancedExtractRefactoringSupport = true,
            advancedOrganizeImportsSupport = true,
            -- 关键优化：关闭高开销功能
            completion = {
              maxResults = 100,    -- 限制补全结果数量
              lazyResolve = false, -- 延迟解析补全项
            },
            shouldLanguageServerExitOnShutdown = true,
          },
        },
        handlers = {
          ["$/progress"] = function() end, -- disable progress updates.
        },
        flags = {
          debounce_text_changes = 200, -- 增加输入防抖
          allow_incremental_sync = true,
        },
        filetypes = { "java" },
        on_attach = function(...)
          require("jdtls").setup_dap({ hotcodereplace = "auto", config_overrides = {} })
          vim.keymap.set("n", "<leader>cc", function()
            utils.info("Compiling Java Project (incremental)...")
            require("jdtls").compile("incremental")
          end, { desc = "Compile Java Project" })
          vim.keymap.set("n", "<leader>cC", function()
            utils.info("Compiling Java Project (full)...")
            require("jdtls").compile("full")
          end, { desc = "Compile Java Project (full)" })
          vim.keymap.set("n", "<leader>cu", function()
            utils.info("Updaing Java Project Configuration...")
            require("jdtls").update_project_config()
          end, { desc = "Update Java Project Configuration" })
        end,
      })
    end,
    config = function(_, opts)
      local wk = require("which-key")
      wk.add({
        {
          mode = "n",
          { "<leader>cx",  group = "extract" },
          { "<leader>cxv", require("jdtls").extract_variable_all, desc = "Extract Variable" },
          { "<leader>cxc", require("jdtls").extract_constant,     desc = "Extract Constant" },
          { "<leader>cgs", require("jdtls").super_implementation, desc = "Goto Super" },
          { "<leader>cgS", require("jdtls.tests").goto_subjects,  desc = "Goto Subjects" },
          { "<leader>co",  require("jdtls").organize_imports,     desc = "Organize Imports" },
        },
      })
      wk.add({
        {
          mode = "v",
          { "<leader>cx", group = "extract" },
          {
            "<leader>cxm",
            [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
            desc = "Extract Method",
          },
          {
            "<leader>cxv",
            [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
            desc = "Extract Variable",
          },
          {
            "<leader>cxc",
            [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
            desc = "Extract Constant",
          },
        },
      })
      wk.add({
        {
          mode = "n",
          { "<leader>t",  group = "test" },
          {
            "<leader>tt",
            function()
              require("jdtls.dap").test_class({
                config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
              })
            end,
            desc = "Run All Test",
          },
          {
            "<leader>tr",
            function()
              require("jdtls.dap").test_nearest_method({
                config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
              })
            end,
            desc = "Run Nearest Test",
          },
          { "<leader>tT", require("jdtls.dap").pick_test, desc = "Run Test" },
        },
      })

      -- setup autocmd on filetype detect java
      vim.api.nvim_create_autocmd("Filetype", {
        pattern = "*.java", -- autocmd to start jdtls
        callback = function()
          if opts.root_dir and opts.root_dir ~= "" then
            require("jdtls").start_or_attach(opts)
          else
            utils.error("jdtls: root_dir not found. Please specify a root marker")
          end
        end,
      })
      -- create autocmd to load main class configs on LspAttach.
      -- This ensures that the LSP is fully attached.
      -- See https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.java",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          -- ensure that only the jdtls client is activated
          if client.name == "jdtls" then
            require("jdtls.dap").setup_dap_main_class_configs()
          end
        end,
      })
      require("jdtls").start_or_attach(opts)
    end,
  },
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "jproperties" },
    specs = {
      {
        "mfussenegger/nvim-jdtls",
        optional = true,
        opts = function(_, opts)
          if not opts.init_options then
            opts.init_options = {}
          end
          if not opts.init_options.bundles then
            opts.init_options.bundles = {}
          end
          vim.list_extend(opts.init_options.bundles, require("spring_boot").java_extensions())
        end,
      },
    },
    opts = {
      java_cmd = "/usr/lib/jvm/java-21-openjdk/bin/java",
      exploded_ls_jar_data = true,
    },
  },
  {
    "rcasia/neotest-java",
    ft = "java",
    dependencies = {
      "mfussenegger/nvim-dap", -- for the debugger
      "rcarriga/nvim-dap-ui",  -- recommended
    },
  },
  {
    "nvim-neotest/neotest",
    opts = function(_, opts)
      if not opts.adapters then
        opts.adapters = {}
      end
      table.insert(opts.adapters, require("neotest-java")({}))
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        java = { "google-java-format" },
      },
    },
  },
  {
    "alessio-vivaldelli/java-creator-nvim",
    config = function()
      require("java-creator-nvim").setup({
        options = {
          java_version = 17,
          auto_open = true,
          use_notify = true,
          custom_src_path = "backend/src/main/java",
          src_patterns = { "src/main/java", "src/test/java", "src" },
          project_markers = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", ".project" },
          notification_timeout = 3000,
        },
        keymaps = {
          java_new = "<leader>jn",
          java_class = "<leader>jc",
          java_interface = "<leader>ji",
          java_enum = "<leader>je",
          java_record = "<leader>jr",
        },
        default_imports = {
          record = { "java.util.*" },   -- Import di default per i record
        },
      })

      vim.keymap.set("i", "<C-space>", 'pumvisible() ? "\\<C-n>" : "\\<C-x>\\<C-u>"', {
        expr = true,
        desc = "",
      })
    end,
    ft = "java",
    event = "VeryLazy",
    dependencies = {
      { "rcarriga/nvim-notify", optional = true },
    },
  }
}
