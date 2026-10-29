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
in
{
  home.packages = with pkgs; [
    go
    rustc
    cargo
    nodejs
    yarn

    # Java 工具链。**只放一个 JDK**：home-manager 的 home.path 是
    # `buildEnv { paths = cfg.packages; }`，没传 ignoreCollisions（默认 false），
    # 同时放 jdk17 + jdk21 会在 bin/java 上撞车、构建直接失败。
    # 真要多个版本并存，走 direnv + 项目内 devShell（cli.nix 已经装了 direnv/nix-direnv），
    # 别往这里堆。
    # gradle 顶层默认是 gradle_8（8.14.4）；要 7/9 写 gradle_7 / gradle_9。
    javaJdk
    maven
    gradle

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
}
