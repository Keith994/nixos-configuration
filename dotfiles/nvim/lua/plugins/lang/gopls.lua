local create_command = vim.api.nvim_create_user_command
local list_insert_unique = utils.list_insert_unique

local is_test_file = function()
  local file = vim.fn.expand("%")
  if #file <= 1 then
    vim.notify("no buffer name", vim.log.levels.ERROR)
    return
  end
  local is_test = string.find(file, "_test%.go$")
  local is_source = string.find(file, "%.go$")
  return file, (not is_test and is_source), is_test
end

local alternate = function()
  local file, is_source, is_test = is_test_file()
  local alt_file = file
  if is_test then
    alt_file = string.gsub(file, "_test.go", ".go")
  elseif is_source then
    alt_file = vim.fn.expand("%:r") .. "_test.go"
  else
    vim.notify("not a go file", vim.log.levels.ERROR)
  end
  return alt_file
end

local switch = function(bang, cmd)
  local alt_file = alternate()
  if not vim.fn.filereadable(alt_file) and not vim.fn.bufexists(alt_file) and not bang then
    vim.notify("couldn't find " .. alt_file, vim.log.levels.ERROR)
    return
  elseif #cmd <= 1 then
    local ocmd = "e " .. alt_file
    vim.cmd(ocmd)
  else
    local ocmd = cmd .. " " .. alt_file
    vim.cmd(ocmd)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      local ret = {
        servers = {
          gopls = {
            settings = {
              gopls = {
                analyses = {
                  ST1003 = false,
                  fieldalignment = false,
                  fillreturns = true,
                  nilness = true,
                  nonewvars = true,
                  shadow = true,
                  undeclaredname = false,
                  unreachable = true,
                  unusedparams = false,
                  unusedwrite = false,
                  useany = true,
                },
                codelenses = {
                  gc_details = true, -- Show a code lens toggling the display of gc's choices.
                  generate = true,   -- show the `go generate` lens.
                  regenerate_cgo = true,
                  test = true,
                  tidy = true,
                  upgrade_dependency = true,
                  vendor = true,
                },
                hints = {
                  assignVariableTypes = true,
                  compositeLiteralFields = true,
                  compositeLiteralTypes = true,
                  constantValues = true,
                  functionTypeParameters = true,
                  parameterNames = true,
                  rangeVariableTypes = true,
                },
                buildFlags = { "-tags", "integration" },
                completeUnimported = true,
                diagnosticsDelay = "500ms",
                matcher = "Fuzzy",
                semanticTokens = true,
                staticcheck = false,
                symbolMatcher = "fuzzy",
                usePlaceholders = true,
              },
            },
          },
        },
      }
      -- ensure_installed 必须**追加**，不能留在 ret 里交给 extend_tbl：
      -- 后者底层是 vim.tbl_deep_extend("force")，对数组是按下标覆盖，
      -- 会冲掉别的 lang 文件已经塞进去的项。详见 lang/java.lua 的注释。
      -- 这批 Go 工具走的是 mason 的 golang/npm manager（proxy.golang.org），
      -- 不是 GitHub Releases，所以本机装得下来，来源不动、只修合并方式。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
        "delve",
        "gopls",
        "gomodifytags",
        "gofumpt",
        "gotests",
        "goimports",
        "iferr",
        "impl",
      })
      return utils.extend_tbl(opts, ret)
    end,
  },
  -- Golang support
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = list_insert_unique(opts.ensure_installed, { "go", "gomod", "gosum", "gowork" })
      end
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.code_actions.gomodifytags,
        nls.builtins.code_actions.impl,
        -- nls.builtins.formatting.goimports,
        -- nls.builtins.formatting.gofumpt,
      })
    end,
  },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = {
      "mfussenegger/nvim-dap",
      "jay-babu/mason-nvim-dap.nvim",
    },
    -- 这里**必须**有全局 setup：neotest-golang 的 `:Neotest debug` 会临时调一次
    -- dap-go.setup(...) 再还原，但 `:DapNew` / `<leader>dc` 走的是全局 adapter 与
    -- configurations，没这一步就根本选不到 Go 的 launch 配置。
    opts = function()
      -- dlv 走 mason 的绝对路径（同上：正常启动时 PATH 上没有 dlv）
      local dlv = vim.fn.expand("~/.local/share/nvim/mason/bin/dlv")
      -- 与 run.sh 保持同一套构建参数；逗号形式，原因见下面 neotest 那段注释
      local tags = "-tags=with_iot,with_extend"

      require("dap-go").setup({ delve = { path = dlv } })

      local dap = require("dap")
      dap.configurations.go = dap.configurations.go or {}

      -- 1) 调试整个 server（= run.sh 干的事：go run -tags ... ./cmd/server -c <conf>）
      --    调试启动是 `go build` 出二进制再 dlv 执行，等价于 run.sh 的骨架；
      --    cwd 必须是仓库根，因为 -c 的相对路径与配置里的插件目录都按仓库根解析。
      --
      -- 【坑，实测 2026-11-04】args **不能写成 function**。nvim-dap 只对配置里的
      -- 字符串做 ${var} 展开（dap.lua 的 expand_config_variables），不会调用 args 函数；
      -- 函数会被原样塞进 DAP 的 launch 参数，dlv 收到后直接 Failed to launch。
      --
      -- 这条与团队在 VS Code 里能跑的那份 launch.json 对齐（program / args 都用
      -- ${workspaceFolder} 绝对路径、带 env.CGO_CFLAGS），已实测在 nvim 内
      -- `dap.run` 能正常 Building 起来并 attach（sess.closed=false, initialized=true）。
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Debug server (cmd/server, with_iot+with_extend)",
        request = "launch",
        mode = "debug",
        -- 必须是**目录**（整个包），写成 ./cmd/server/server.go 只编单文件，
        -- register_plugins.go / with_iot.go / with_extend.go 都不会被编进去。
        program = "${workspaceFolder}/cmd/server",
        args = { "-c", "${workspaceFolder}/config_cloud.local_keith.conf" },
        buildFlags = tags,
        cwd = "${workspaceFolder}",
        -- 与 VS Code 配置保持一致：Nix 的 gcc 15 默认把告警当错误，
        -- -Wno-error 让 cgo 侧告警不至于中断调试构建。
        env = { CGO_CFLAGS = "-O2 -g -Wno-error" },
        -- 【坑，实测 2026-11-04】我们 table.insert 的配置**不走** dap-go 的
        -- setup_go_configuration，它默认的 output_mode 不会自动带上来。
        -- dlv 规则：outputMode=remote 时才把被调程序的 stdout/stderr 包成 DAP 的
        -- output 事件；再给 console 才真正转给客户端。缺一个，程序输出就被 delve
        -- 吞掉，dapui 的 console 只剩 "Building ..." / "Type 'dlv help' ..." 两行。
        -- （程序自己写文件或走 logger 不受影响，只是终端里看不到。）
        outputMode = "remote",
        console = "integratedTerminal",
      })

      -- 2) 调试整个 server，用相对路径（cwd=${workspaceFolder} 下等价于上面那条）
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Debug server (default conf)",
        request = "launch",
        mode = "debug",
        program = "./cmd/server",
        args = { "-c", "config_cloud.local_keith.conf" },
        buildFlags = tags,
        cwd = "${workspaceFolder}",
        env = { CGO_CFLAGS = "-O2 -g -Wno-error" },
        outputMode = "remote",
        console = "integratedTerminal",
      })

      -- 3) 调试仓库里某个可执行包：program 用 ${fileDirname}，所以只在 main 包目录下的
      --    文件里选它才有意义（如 cmd/server/、cmd/*），在 data/plugins 这种库包里选会
      --    报 build 失败 —— 库包没有 main 函数，dlv 无法执行。调试库包里的代码请走
      --    `:Neotest debug`（测试调试）或者从 server 的断点跟进去。
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Debug current package (main packages only)",
        request = "launch",
        mode = "debug",
        program = "${fileDirname}",
        buildFlags = tags,
        cwd = "${workspaceFolder}",
      })

      return {}
    end,
  },
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    build = function()
      if not require("lazy.core.config").spec.plugins["mason.nvim"] then
        vim.print("Installing go dependencies...")
        vim.cmd.GoInstallDeps()
      end
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "mason-org/mason.nvim", optional = true }, -- by default use Mason for go dependencies
    },
    opts = function(_, opts)
      create_command("GoAlt", function()
        switch(nil, "")
      end, { desc = "Alt File" })
      create_command("GoAltV", function()
        switch(nil, "vsplit")
      end, { desc = "Alt File vsplit" })
      create_command("GoAltS", function()
        switch(nil, "vsplit")
      end, { desc = "Alt File split" })
      return utils.extend_tbl(opts, {
        gotag = {
          transform = "camelcase",
          -- default tags to add to struct fields
          default_tag = "json",
        },
      })
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { {
      "fredrikaverpil/neotest-golang",
      version = "*",                                                            -- Optional, but recommended; track releases
      build = function()
        vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait() -- Optional, but recommended
      end,
    } },
    opts = function(_, opts)
      if not opts.adapters then
        opts.adapters = {}
      end
      -- neotest 用 tree-sitter 发现测试位置。缺 go parser 时 discover_positions
      -- 抛错，neotest 退回 file/test 级 runspec，而这两处只认 args.strategy == "dap"：
      -- 默认 integrated 策略拿不到 command，build_spec 返回 { strategy = {} }，
      -- dap 策略见 spec.strategy 为空就 return nil，runner.lua:57 索引 nil 的
      -- instance，报出那句没头没尾的 "attempt to index local 'instance' (a nil value)"。
      -- gopls.lua 上面的 treesitter ensure_installed 只在打开 go 文件时生效，
      -- 目录级 `:Neotest run` / 首屏就跑测试时可能还没装，这里兜底补一次。
      -- （treesitter main 分支并不消费 opts.ensure_installed，真正安装的是
      -- plugins/treesitter.lua 里 config 函数那段 install 逻辑，所以要 lazy.load。）
      vim.defer_fn(function()
        local missing = {}
        for _, lang in ipairs({ "go", "gomod", "gosum", "gowork" }) do
          if not TSUtils.have(lang) then
            list_insert_unique(opts.ensure_installed, { lang })
            table.insert(missing, lang)
          end
        end
        if #missing > 0 then
          require("lazy").load({ plugins = { "nvim-treesitter" } })
        end
      end, 100)
      table.insert(opts.adapters, require("neotest-golang")({
        runner = "gotestsum", -- Optional, but recommended
        -- 这个仓库的 run.sh 用 `-tags "with_iot with_extend"` 构建（见仓库根 run.sh），
        -- 测试也得带上同样的 tags，否则 register_plugins.go / with_iot.go 那批文件
        -- 不参与编译。另外 data/plugins 里有大量 `fmt.Errorf(非字面量)`，go vet
        -- （go1.24 起是 go test 默认步骤）会直接 build failed —— neotest-golang 会把
        -- 这种失败静默标成 skipped（runspec/file.lua:18 "No tests found in file"），
        -- 看着就像"跑了但没结果"，所以必须 -vet=off。-race 默认参数先去掉：CGO 环境
        -- 不一定齐，而且 neotest-golang 对 -race 有 CGO 校验、失败会直接 error。
        go_test_args = { "-vet=off", "-count=1", "-tags", "with_iot with_extend" },
        gotestsum_args = { "--format=testname" },
        -- `:Neotest debug` 走 dap 策略，neotest-golang 的 dap runspec（dap_go.lua）
        -- **不读** go_test_args，buildFlags 只从 dap_go_opts.delve.build_flags 拿；
        -- 不带 tags 的话 delve 编译出来的测试二进制和 run.sh 不是同一套代码。
        --
        -- 【坑，实测 2026-11-04】tags 必须写成 `-tags=a,b` 逗号形式，**绝不能**用空格：
        -- nvim-dap-go 把 build_flags 用 `table.concat(x, " ")` 拼成一个字符串塞进 DAP 的
        -- buildFlags，dlv 收到后再按空格切词，于是
        --   { "-tags", "with_iot with_extend" }  ->  ... -tags with_iot with_extend ...
        -- 被切成 "-tags with_iot" + 多出一个包名 "with_extend"，报
        --   `package with_extend is not in std`，:Neotest debug 直接 Failed to launch。
        -- 真实命令（从 dlv DAP 的 output 事件里抓的）：
        --   go test -c -o __debug_bin... -gcflags all=-N -l \
        --     -tags with_iot with_extend -vet off <testdir>
        -- 用逗号合进同一个 token 就没有二次切词问题；-vet=off 同理写成等号形式。
        -- 已用真实 DAP 协议验证：launch success=true。
        --
        -- delve.path 用 mason 装的绝对路径：mason.nvim 只在「安装动作」时才设
        -- vim.env.MASON / PATH，正常启动后 nvim-dap-go 默认的 `dlv` 不在 PATH 上，
        -- adapter 起不来就是静默失败（见 util/treesitter.lua 同款 $MASON expand 坑）。
        -- 注意 vim.fn.glob(x, true, false) 返回的是**字符串**不是列表，别 [1]。
        --
        -- 为什么 nvim 里不能靠 `go test -tags "a b"` 的经验照搬：普通 go 命令由 sh 切词，
        -- 引号能保住空格；dlv 的 buildFlags 是「再切一次词」的字符串，没有 sh 语义。
        dap_go_opts = {
          delve = {
            path = vim.fn.expand("~/.local/share/nvim/mason/bin/dlv"),
            build_flags = { "-tags=with_iot,with_extend", "-vet=off" },
          },
        },
      }))
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt", lsp_format = "last" },
      },
    },
  },
  {
    "echasnovski/mini.icons",
    optional = true,
    opts = {
      file = {
        [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
      },
      filetype = {
        gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
      },
    },
  },
}
