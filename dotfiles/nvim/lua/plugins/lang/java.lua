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

-- JDK 由 home-manager 提供（modules/home/devtools.nix 里的 javaJdk + JAVA_HOME）。
-- NixOS 上没有 /usr/lib/jvm 这种发行版约定路径，也没有 jenv / sdkman，
-- 所以这里一律从 PATH 和 $JAVA_HOME 推导，**不写死 store 路径**：
-- store 路径进 dotfiles 会在每次 nix flake update 之后产生一行无意义的 diff。
local function java_exe()
  local exe = vim.fn.exepath("java")
  return (exe ~= "" and exe) or "java"
end

-- jdtls 的 java.configuration.runtimes：从 $JAVA_HOME/release 的 JAVA_VERSION 推出执行环境名，
-- 这样在 devtools.nix 里换 JDK 版本（jdk21 → jdk17 / jdk8），这个文件一行都不用改。
-- 需要多版本并存时也别往 home.packages 里堆 JDK：home-manager 的 home.path 是
-- buildEnv（不忽略冲突），两个 JDK 会在 bin/java 上撞车直接构建失败 ——
-- 改用 direnv + 项目内 devShell，每个项目自己选。
local function java_runtimes()
  local home = vim.env.JAVA_HOME
  if not home or home == "" then
    return {}
  end
  local f = io.open(home .. "/release", "r")
  if not f then
    return {}
  end
  local raw = f:read("*a"):match('JAVA_VERSION="([^"]+)"')
  f:close()
  -- JDK 8 的 release 写的是 "1.8.0_xxx"，执行环境名是 JavaSE-1.8；9 及以后才是 JavaSE-<major>
  local feature = raw and (raw:match("^1%.%d+") or raw:match("^%d+"))
  if not feature then
    return {}
  end
  return { {
    name = "JavaSE-" .. feature,
    path = home,
    default = true,
  } }
end

-- 把 nixpkgs 的 jdt-language-server 从 PATH 上反查出来。
-- 为什么需要这条路：home.sessionVariables.JDTLS_HOME 只在**新会话**里才有 ——
-- `nr` 之后不重开 shell / 不重登桌面就拿不到（JAVA_HOME 是老早设好的所以一直在，
-- 容易让人误以为 JDTLS_HOME 也该在）。而 ~/.nix-profile/bin 是**原地更新**的软链农场，
-- `nr` 一结束 PATH 上立刻就能解析到 jdtls：实测 exepath("jdtls") 命中
-- /etc/profiles/per-user/keith/bin/jdtls，顺着软链 realpath 到
-- /nix/store/<hash>-jdt-language-server-<ver>/bin/jdtls，再走两层 dirname 就是 store 根。
local function jdtls_from_path()
  local exe = vim.fn.exepath("jdtls")
  if exe == "" then
    return nil
  end
  local real = (vim.uv.fs_realpath and vim.uv.fs_realpath(exe)) or exe
  local root = vim.fn.fnamemodify(vim.fn.fnamemodify(real, ":h"), ":h")
  return root .. "/share/java/jdtls"
end

-- mason 的安装根目录走公共 helper（见 lua/util/init.lua 的 M.mason_root）：
-- 那里写清了为什么不能用 vim.fn.expand("$MASON/...") —— 简短版是 mason.nvim 只在
-- InstallLocation.lua 里设 vim.env.MASON（安装/卸载时才跑），正常启动不会设，
-- 而 expand 对未设置变量做**空前缀替换**，"$MASON/share/jdtls" 会变成 "/share/jdtls"，
-- 一个不存在却长得像绝对路径的字符串，fs_stat 静默失败。
-- 这次排查就是被它坑的：mason 明明把 jdtls 装好了，探测却报"没装"。
local function mason_root()
  return utils.mason_root()
end

-- jdtls 本体按优先级探测，谁在就用谁：
--   1. $JDTLS_HOME              —— nixpkgs，home-manager 显式设的（需要新会话才可见）
--   2. exepath("jdtls") 反查     —— nixpkgs，同上但**当前会话就能用**
--   3. <mason 根>/share/jdtls    —— mason 兜底
-- 布局差异：nixpkgs 是 {plugins,features,config_linux} 且**不带 lombok.jar**；
-- mason 是 {plugins,config} 并附带 lombok.jar（走软链指向 packages/jdtls/lombok.jar）。
-- 所以走 nix 那条路时 lombok 注解（@Data / @Builder 之类）不被识别 ——
-- 需要 lombok 就把 mason 那份提到前面，或者只依赖 mason。
local function jdtls_home()
  -- 候选表**不能**写成 `{ vim.env.JDTLS_HOME, jdtls_from_path(), … }` 再交给 ipairs：
  -- JDTLS_HOME 没设时第一项就是 nil，Lua 的表成了 `{ [1]=nil, [2]="…" }`，
  -- 而 **ipairs 遇到第一个 nil 就停**（实测这种表 ipairs 产出 0 项），
  -- 于是后面两个候选压根不会被检查 —— nix 和 mason 明明都装好了，却报"没装"。
  -- 这次就是这么坑的。所以显式跳过 nil 再收集，保证表里没有洞。
  -- （`#t` 对带洞的表照样返回 3，所以也别指望用 # 判断，一样不可靠。）
  local candidates = {}
  local function add(dir)
    if dir and dir ~= "" then
      candidates[#candidates + 1] = dir
    end
  end
  add(vim.env.JDTLS_HOME)
  add(jdtls_from_path())
  local mroot = mason_root()
  if mroot then
    add(mroot .. "/share/jdtls")
  end
  for _, dir in ipairs(candidates) do
    if dir and dir ~= "" and vim.uv.fs_stat(dir .. "/plugins") then
      return dir
    end
  end
  return nil
end

-- launcher jar 必须 glob，不能写死文件名。上游 jdtls.py 的 find_equinox_launcher()
-- 就是这个顺序，照抄：
--   1. 无版本名的 org.eclipse.equinox.launcher.jar —— 上游注释写明这是
--      "mason-registry packaging"，只有 mason 重新打包过才有；
--   2. 否则 glob org.eclipse.equinox.launcher_*.jar —— eclipse 官方 tarball
--      （也就是 nixpkgs 那份）里只有这种带版本号的
--      org.eclipse.equinox.launcher_1.6.x.y.vYYYYMMDD-HHMM.jar。
-- 这里以前写死第 1 种，所以走 nix 路线必然 "Unable to access jarfile" 退出 1。
-- 注意 glob 里那个下划线：只有 org.eclipse.equinox.launcher_*.jar 才排得掉
-- org.eclipse.equinox.launcher.gtk.linux.x86_64_*.jar /
-- org.eclipse.equinox.launcher.cocoa.macosx.x86_64_*.jar 这类平台 fragment
-- （实测 tarball 里这三类 fragment 确实都叫 org.eclipse.equinox.launcher.* ）。
local function jdtls_launcher(home)
  local literal = home .. "/plugins/org.eclipse.equinox.launcher.jar"
  if vim.uv.fs_stat(literal) then
    return literal
  end
  local jars = vim.fn.glob(home .. "/plugins/org.eclipse.equinox.launcher_*.jar", true, true)
  table.sort(jars)
  return jars[#jars]
end

-- OSGi 配置目录：上游 jdtls.py 的 get_shared_config_path() 在 Linux 上**永远**返回
-- config_linux，而 mason 的打包可能把它改名成 config，所以两个都探、优先 config_linux。
local function jdtls_config(home)
  for _, name in ipairs({ "config_linux", "config" }) do
    if vim.uv.fs_stat(home .. "/" .. name) then
      return home .. "/" .. name
    end
  end
  return nil
end

-- JDK 主版本号，从 $JAVA_HOME/release 读（和 java_runtimes 同一个来源，不额外起子进程）。
-- 用途见下面 cmd 里的 -Djdk.xml.*：jdtls 在 JDK 24+ 上需要显式放开 XML 实体上限。
-- devtools.nix 明说换 JDK 只改一行（jdk8/11/17/21/25 都有），所以这里跟着 release 走，
-- 别写死版本号。
local function java_major()
  local home = vim.env.JAVA_HOME
  if not home or home == "" then
    return nil
  end
  local f = io.open(home .. "/release", "r")
  if not f then
    return nil
  end
  local raw = f:read("*a"):match('JAVA_VERSION="([^"]+)"')
  f:close()
  local feature = raw and (raw:match("^1%.(%d+)") or raw:match("^(%d+)"))
  return feature and tonumber(feature) or nil
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
      -- ensure_installed 必须用 list_insert_unique **追加**。
      -- 不能写成 utils.extend_tbl(opts, { ensure_installed = { ... } })：
      -- extend_tbl 底层是 vim.tbl_deep_extend("force")，它对数组是**按下标覆盖**而不是拼接。
      -- 7 个 lang 文件各写一份列表时，最后只剩最长那份的几个元素活着 ——
      -- 实测合并结果是 { "lemminx", "codelldb" }（index 1 被 lang/xml.lua 抢走、
      -- index 2 被 lang/rust.lua 抢走），和 mason.log 里「只尝试过这两个包」完全对上。
      -- 这正是 jdtls 从来没被 mason 装过的原因：写进列表也会被别的文件冲掉。
      opts.ensure_installed = utils.list_insert_unique(opts.ensure_installed or {}, {
        -- mason 只是 jdtls 的**兜底**来源，主路径是 nixpkgs（见上面 jdtls_home 的注释）。
        -- 源是 download.eclipse.org，本机实测只有约 17KB/s，51MB 要下将近一小时，
        -- 期间别关 nvim —— mason 在 nvim 退出时会 abort 安装（mason.log 里
        -- codelldb 那 133 次 "Installation was aborted" 就是这么来的）。
        "jdtls",
      })
      -- 刻意**不**列 java-debug-adapter / java-test / google-java-format：
      -- 它们在 mason registry 里都是 pkg:github/...，本机直连 GitHub Releases 超时
      -- （实测 25s 收到 0 字节），列进来只会在每次启动时刷失败日志、拖慢启动。
      --   - google-java-format 改由 nixpkgs 提供（modules/home/devtools.nix），
      --     conform.nvim 直接在 PATH 上就能找到；
      --   - java-debug-adapter / java-test 是 DAP 调试和单测用的 bundle，缺了只是
      --     下面那几个 glob 拿到空表（不报错），jdtls 本体照常工作，
      --     代价是 F5 调试和 <leader>tt 跑测试不可用。要恢复就得先让 GitHub 可达
      --     （给 nvim 配 https_proxy 走 clash 的 10800），别指望 mason 自己重试成功。
      opts.servers = utils.extend_tbl(opts.servers or {}, { jdtls = {} })
      -- 以前这里还有个 setup = { jdtls = function() return true end }，用来告诉
      -- lsp.lua 的 mason-lspconfig handler「跳过 jdtls，交给 nvim-jdtls」。
      -- mason-lspconfig v2 删掉了 handlers，那段 handler 已经是死代码（见 lsp.lua），
      -- 所以这个 setup 表也没有任何消费者了，一并去掉。
      return opts
    end,
  },

  -- Set up nvim-jdtls to attach to java files.
  {
    "mfussenegger/nvim-jdtls",
    event = { "BufReadPost *.java" },
    dependencies = { "folke/which-key.nvim", "nvim-lspconfig" },
    opts = function(_, opts)
      -- 先解析 jdtls 本体，**放在 root_dir 之前**：这样"没装 jdtls"这条错误在任何
      -- 目录下都能报出来，不会被 vim.fs.dirname(nil) 之类的问题盖掉。
      -- home 为 nil 时绝不去拼 cmd —— java 拿到一个不存在的 -jar 只会打一句
      -- "Error: Unable to access jarfile ..." 然后退出 1，nvim 侧显示成
      -- "Client jdtls quit with exit code 1 and signal 0"，从提示上完全看不出是缺文件
      -- （这次排查就是被它绕了一圈）。宁可在这里把话说清楚。
      local home = jdtls_home()
      local launcher = home and jdtls_launcher(home) or nil
      if not launcher then
        utils.error(table.concat({
          "jdtls 没装好：找不到 org.eclipse.equinox.launcher*.jar，已跳过启动。",
          "",
          "探测过的位置（按优先级）：",
          "  1. $JDTLS_HOME/plugins             nixpkgs；这个变量要**新会话**才有",
          "  2. exepath('jdtls') 反查的 store    nixpkgs；当前会话就能用",
          "  3. <mason 根>/share/jdtls/plugins   mason 兜底",
          "",
          "修法二选一：",
          "  1) nix（推荐）：跑 nr 装 jdt-language-server（devtools.nix）。",
          "     注意 $JDTLS_HOME 属于 home.sessionVariables，`nr` 完**当前会话里仍然是空的**，",
          "     要重开 shell / 重登桌面才有 —— 但上面第 2 条不依赖它：~/.nix-profile/bin 是",
          "     原地更新的软链农场，`nr` 一结束 PATH 上就能解析到 jdtls，不必重启会话。",
          "  2) mason（兜底）：:MasonInstall jdtls（源是 download.eclipse.org）。",
          "     mason 那份更新（1.63 vs nixpkgs 1.58）而且**带 lombok.jar**，",
          "     需要 lombok 注解支持就把它排到前面。",
          "",
          "自查： :lua =vim.fn.exepath('jdtls')   :lua =require('util').mason_root()",
        }, "\n"))
        -- cmd 留空：下面的 Filetype autocmd 和末尾的 start_or_attach 都会因此跳过。
        return opts
      end

      local root_dir =
          vim.fs.dirname(vim.fs.find({ ".git", "pom.xml", ".project", "gradlew", "mvnw" }, { upward = true })[1])
      local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
      local workspace_dir = vim.fn.expand("$HOME/.cache/jdtls/" .. project_name)
      local cmd = {
        java_exe(),
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        -- "-Dlog:disable",
        -- "-Djdt.ls.debug=false",
        "-Dlombok.disableConfig=true",
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
        -- 注意 `-jar` 及其之后的东西**刻意不在这里**，见下面两段 ——
        -- JVM 系统属性和 equinox 程序参数必须分别排在 -jar 的前/后，放错了会静默失效。
      }

      -- 这四个 -Dosgi.* 是 **JVM 系统属性，必须排在 `-jar` 之前**：JVM 只解析 -jar 之前的
      -- 选项，-jar 之后的一律当成传给 main 类的应用参数。以前用 vim.list_extend 把它们
      -- 追加到整条命令的末尾，equinox 压根没收到 → 退回默认的
      -- ~/.eclipse/<hash>/configuration，撞上 org.eclipse.osgi/.manager/.fileTableLock
      -- 的权限/锁问题，java 以退出码 **13** 结束（nvim 侧显示
      -- "Client jdtls quit with exit code 13 and signal 0"，而 lsp.log 里那条
      -- "Error reading configuration … (Permission denied)" 才是真正的线索）。
      --
      -- 为什么不直接 `-configuration <nix 的 config_linux>`：equinox 会把它当**可写**
      -- 配置区、往里写 .manager/.fileTableLock，而 nix store 是只读的，写了就起不来。
      -- sharedConfiguration.area + readOnly=true + cascaded=true 才是"共享只读父配置 +
      -- 实例配置级联到可写位置"，nix（只读）和 mason（可写）两条路线都成立。
      local configuration = jdtls_config(home)
      if configuration then
        vim.list_extend(cmd, {
          "-Dosgi.checkConfiguration=true",
          "-Dosgi.sharedConfiguration.area=" .. configuration,
          "-Dosgi.sharedConfiguration.area.readOnly=true",
          "-Dosgi.configuration.cascaded=true",
        })
      end

      -- 实例配置区显式指到 workspace 旁边的可写目录，**不要**用 equinox 默认的
      -- ~/.eclipse/<hash>/configuration：那个位置跨项目共享，而且 nixpkgs 的 bin/jdtls
      -- 包装脚本和这里 nvim-jdtls 的自定义 cmd 会从同一个 sharedConfiguration.area 算出
      -- **同一个 <hash>**、去抢同一个 .fileTableLock —— 实测就是 exit 13。
      -- 放到项目自己的目录下顺带做到各工程互不干扰、删 workspace 就一起清掉。
      -- `-configuration` 是 **equinox 的程序参数**（不是 JVM 属性），所以排在 -jar 之后；
      -- 下面 lombok / jdk24 那两处 table.insert(cmd, 2, …) 插在最前面，不会跑到 -jar 之后。
      vim.list_extend(cmd, {
        "-jar",
        launcher,
        "-configuration",
        workspace_dir .. "-osgi",
        "-data",
        workspace_dir,
      })

      -- jdtls 在 JDK 24+ 上要显式放开 XML 实体上限，否则解析大 POM / 大 XML 会失败。
      -- 现在是 jdk21 用不上，但 devtools.nix 明说换 JDK 只改一行（jdk25 就在手边），
      -- 所以按 $JAVA_HOME/release 动态判断，别等真换了才来 debug。
      local major = java_major()
      if major and major >= 24 then
        table.insert(cmd, 2, "-Djdk.xml.maxGeneralEntitySizeLimit=0")
        table.insert(cmd, 2, "-Djdk.xml.totalEntitySizeLimit=0")
      end

      -- lombok.jar 只有 mason 那条路才带（nixpkgs 的 jdt-language-server 不含它）。
      -- 缺文件时 JVM 会以 "Error opening zip file or JAR manifest missing" 硬失败，
      -- 比不带 lombok 更糟，所以先 stat 再塞。插在第 2 位（紧跟 java 可执行文件）——
      -- -javaagent 是 JVM 参数，必须排在 -jar 之前。
      local lombok_jar = home .. "/lombok.jar"
      if vim.uv.fs_stat(lombok_jar) then
        table.insert(cmd, 2, "-javaagent:" .. lombok_jar)
      end

      -- 这两个 glob 以前都写成 "$MASON/..."，各错一处：
      --   * java-debug-adapter 那行用了 vim.fn.expand，但 $MASON 通常没设
      --     （见 util/init.lua 的 M.mason_root 注释）→ 变成 "/share/java-debug-adapter/…"；
      --   * java-test 那行**连 expand 都没调**，而 vim.fn.glob 不展开环境变量
      --     → 拿字面量 "$MASON/share/java-test/*.jar" 去匹配，永远为空。
      -- 也就是说 DAP 调试和单测的 bundle 从来没被真正加载过。统一改用 mason_root()。
      --
      -- 第三个参数一律给 true 拿**列表**：以前是 vim.split(vim.fn.glob(…), "\n")，
      -- glob 没匹配时返回空串，split 出来是 { "" } —— 一个含空字符串的列表，
      -- 会把 "" 当成 bundle 路径塞进 init_options.bundles。
      local mroot = mason_root()
      local bundles =
          vim.fn.glob(mroot .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar", false, true)
      -- java-test also depends on java-debug-adapter.
      local java_test_bundles = vim.fn.glob(mroot .. "/share/java-test/*.jar", false, true)

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
      -- 按 realpath 去重：mason 的 share/java-test/ 底下同一个 jar 挂了**两个软链**
      -- （实测 com.microsoft.java.test.plugin.jar 和 com.microsoft.java.test.plugin-0.43.1.jar
      --  都指向 packages/java-test/extension/server/…plugin-0.43.1.jar），
      -- glob 会把两个都捞出来。同一个 bundle 塞两遍轻则告警、重则加载失败，
      -- 而按文件名去重没用（两个名字本来就不同），所以比 realpath。
      -- java-debug-adapter 那边同理，但上面用的是精确文件名而不是 *.jar，本来就只有一个。
      local seen = {}
      for _, java_test_jar in ipairs(java_test_bundles) do
        local fname = vim.fn.fnamemodify(java_test_jar, ":t")
        local real = (vim.uv.fs_realpath and vim.uv.fs_realpath(java_test_jar)) or java_test_jar
        if not vim.tbl_contains(excluded, fname) and not seen[real] then
          seen[real] = true
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
              runtimes = java_runtimes(),
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
          -- opts.cmd 为 nil 说明上面 jdtls_home()/jdtls_launcher() 没找到本体，
          -- 那次已经弹过一条详细的错误了，别每开一个 .java 再刷一遍。
          if not opts.cmd then
            return
          end
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
      -- jdtls 本体缺失时 opts.cmd 是 nil，这里必须跳过：nvim-jdtls 会拿 cmd[1] 去 spawn，
      -- 空 cmd 只会再抛一个更难懂的错。缺文件的提示上面已经给过了。
      if opts.cmd then
        require("jdtls").start_or_attach(opts)
      end
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
      java_cmd = java_exe(),
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
