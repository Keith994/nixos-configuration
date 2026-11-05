{ pkgs, ... }:

let
  # 换 JDK 版本只改这一行：26.05 里有 jdk8 / jdk11 / jdk17 / jdk21 / jdk25，
  # `pkgs.jdk` 是 jdk21 的别名。JAVA_HOME 和 nvim 的 jdtls runtimes 都跟着它走
  # （后者从 $JAVA_HOME/release 推导，不写死版本，见 dotfiles/nvim/lua/plugins/lang/java.lua）。
  #
  # 变量名刻意不叫 `jdk`：下面 home.packages 是 `with pkgs; [ ... ]`，
  # 而 pkgs 里正好有个 `jdk` 属性，with 会遮蔽外层 let 绑定 ——
  # 那样改成 jdk17 时列表里仍然静默装 jdk21。
  javaJdk = pkgs.jdk21;

  # jdtls（Eclipse JDT Language Server）走 nixpkgs 而不是 nvim 的 mason.nvim。
  # 决定性的理由**不是速度**，是"这次下载能不能活下来"：
  #   - mason 的 jdtls 从 download.eclipse.org 拉 51MB，本机实测约 17KB/s，要下将近一小时；
  #     而 mason 在 nvim 退出时会 abort 安装 —— mason.log 里 codelldb 那 133 次
  #     "Installation was aborted" 就是这么攒出来的。基本不可能在一次 nvim 会话里下完。
  #   - nix 这边下载归 nix-daemon 管，可以中断续传、跨多次 `nr` 累积，
  #     不依赖某个编辑器进程一直开着。
  # 已核实的事实：cache.nixos.org 上**有**这个产物（narinfo HTTP 200，nar.zst 约 49MB、
  # NarSize 55MB），所以不需要本地构建；它的 References 里那个 openjdk-21.0.12.1
  # 正是上面 javaJdk 已经在用的 store 路径，不会多下一份 JDK。
  # 但别把"有缓存"读成"下得快"：本机当前对外网速整体很差（同一时刻对 cache.nixos.org
  # 的一次 range 取样只有约 1.2KB/s，比 eclipse.org 还慢），第一次 `nr` 可能照样很久 ——
  # 区别在于 nix 慢可以重试续传，mason 慢等于白下。
  # 包名是 jdt-language-server，**不是** jdtls（nixpkgs 里没有 jdtls 这个属性名，
  # `nix eval nixpkgs#jdtls` 会报 "Did you mean one of gitls or natls?"）。
  jdtls = pkgs.jdt-language-server;
in
{
  home.packages = with pkgs; [
    go
    rustc
    cargo

    # node 保持 nixpkgs 的 nodejs（24.x）：iot-edge-ui 的 CI pin 的是 node 20.9，
    # 但那个工程是 vite4 + vue3，24 上跑得动。真要严格对齐 CI 就在工程里
    # `fnm use 20` 或写 devShell，别把全局降到 nodejs_20 —— 会牵连别的项目，
    # 而且 20 已经在 EOL 边缘了。
    nodejs
    yarn

    # pnpm：iot-edge-ui 是 pnpm workspace（pnpm-workspace.yaml + pnpm-lock.yaml），
    # 而系统里原本一个 pnpm 都没有 —— `which pnpm` 偶尔命中的那个是 dsh wrapper 内部的
    # pnpm-only，只存在于 dsh 进程的 PATH 上，普通 shell 拿不到。
    # 版本钉 pnpm_10（10.34）而不是 nixpkgs 默认的 pnpm 11：那个工程的锁文件是
    # lockfileVersion 9.0（pnpm 9/10 写的格式），11 会把它升级重写成 10.0 ——
    # 在共享仓库里就是一条无关的 diff。CI 停在 pnpm 8.x，但 8 根本读不了 9.0 的锁文件，
    # 所以 10 是「能读现有锁文件」里最保守的那一档。
    pnpm_10

    # Java 工具链。**只放一个 JDK**：home-manager 的 home.path 是
    # `buildEnv { paths = cfg.packages; }`，没传 ignoreCollisions（默认 false），
    # 同时放 jdk17 + jdk21 会在 bin/java 上撞车、构建直接失败。
    # 真要多个版本并存，走 direnv + 项目内 devShell（cli.nix 已经装了 direnv/nix-direnv），
    # 别往这里堆。
    # gradle 顶层默认是 gradle_8（8.14.4）；要 7/9 写 gradle_7 / gradle_9。
    javaJdk
    maven
    gradle

    # jdtls 本体。它会顺带在 PATH 上放一个 bin/jdtls（上游的 python 包装脚本），
    # 但 nvim 那边**不用**这个入口 —— lang/java.lua 自己拼 java 命令行（要塞 -Xmx、
    # lombok agent、debug bundles），只从这里取 plugins/ 和 config_linux/ 的路径。
    # 所以 PATH 上多出 jdtls 不会和 nvim-jdtls 抢着起 client；真要避免重复启动，
    # 靠的是 lsp.lua 里 mason-lspconfig 的 automatic_enable = { exclude = [ "jdtls" ]; }。
    jdtls

    # conform.nvim 格式化 java 用（lang/java.lua 里 formatters_by_ft.java）。
    # mason registry 里 google-java-format 是 pkg:github/...，本机直连 GitHub Releases
    # 超时（实测 25s 收 0 字节），所以改从这里提供。Apache-2.0，不涉及 unfree 白名单。
    google-java-format

    lsof
    lazygit
    lazydocker
    trash-cli

    tree-sitter
  ];

  # 必须写 .home（= $out/lib/openjdk），不能直接写包路径：$out 顶层只有 bin / include
  # 的软链，release 文件在 $out/lib/openjdk/release，而 jdtls 和 gradle 都要读它。
  #
  # 走 home 层而不是 NixOS 的 programs.java：那个模块是 environment.shellInit
  # （source jdk 的 setup-hook），只对登录 shell 生效；home.sessionVariables 和
  # nvim.nix 里的 EDITOR 走同一条路，从 niri / foot 起来的进程也拿得到。
  # 顺带：mvn / gradle 的 wrapper 只是 `--set-default JAVA_HOME`，所以这里显式设的优先 ——
  # 别指望 wrapper 兜底，它们的 fallback 是 jdk_headless，不带我们要的那个版本。
  home.sessionVariables.JAVA_HOME = "${javaJdk.home}";

  # 给 nvim 的 lang/java.lua 用来启动 jdtls / spring-boot LS **本体**。
  # 必须和项目 $JAVA_HOME 分开：项目 devShell（比如 scet-iot 的 flake）会把
  # PATH 和 JAVA_HOME 换成 jdk8，但 jdtls 1.58 自己只能跑在 17/21 上 ——
  # 用 jdk8 启动会报 "Unrecognized option: --add-modules=ALL-SYSTEM" 直接退出。
  # 固定指向全局 javaJdk（当前 jdk21）；项目编译目标仍由 java.configuration.runtimes
  # 跟着 $JAVA_HOME 走，两者互不影响。
  home.sessionVariables.JDTLS_JAVA_HOME = "${javaJdk.home}";

  # 给 nvim 的 lang/java.lua 用来定位 jdtls 本体（它按 $JDTLS_HOME → $MASON/share/jdtls
  # 的顺序探测）。和 JAVA_HOME 同理走 sessionVariables，从 niri / foot 起的 nvim 才拿得到。
  #
  # 指向 $out/share/java/jdtls 而不是 $out：nixpkgs 的 installPhase 把上游 tarball 重排过，
  # plugins/ features/ config_linux/ 都落在 share/java/jdtls/ 底下（bin/jdtls 才在 $out/bin）。
  # 这个目录下**没有 lombok.jar** —— 上游 tarball 不带，nixpkgs 也没加，
  # java.lua 那边对 lombok 有 fs_stat 守卫，缺了就静默不带，不影响启动。
  home.sessionVariables.JDTLS_HOME = "${jdtls}/share/java/jdtls";
}
