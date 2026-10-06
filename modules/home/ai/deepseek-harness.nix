{ pkgs, config, ... }:

let
  # 真正启动 dsh 的内部脚本。
  # 这个脚本是在 `npx --package=...` 创建好的环境里运行，
  # 此时 command -v dsh 会找到 npm 包里的 dsh。
  # 这里的 node 是外层 `fnm exec` 放进 PATH 的官方 node（见下面 wrapper 的 text）。
  dshRunner = pkgs.writeShellScript "dsh-runner" ''
    entry="$(readlink -f "$(command -v dsh)")"

    exec node \
      --expose-internals \
      "$entry" \
      "$@"
  '';

  # `dsh plugin` 会把参数转发给 profile 目录里的 pnpm，pnpm 必须在 dsh 进程的
  # PATH 上。但 pkgs.pnpm 自己带一份 node，直接加进 runtimeInputs 会按 PATH 顺序
  # 遮蔽 fnm 给出的官方 node（dsh 的宿主层只认官方构建的 node），所以只暴露它的 bin。
  pnpmOnly = pkgs.symlinkJoin {
    name = "pnpm-only";
    paths = [ pkgs.pnpm ];
    postBuild = ''
      rm -f $out/bin/node $out/bin/npx $out/bin/corepack
    '';
  };

  dsh = pkgs.writeShellApplication {
    name = "dsh";

    # 这里**刻意不放任何 node**：dsh 的宿主层只认官方构建的 node，nixpkgs 自己编的
    # node 会让它在宿主准备阶段硬失败（原因与实测见仓库 AGENTS.md 第 7 节），所以 node
    # 一律用 fnm 取（`fnm exec --using=...`，默认 26，可用 DSH_NODE_VERSION 覆盖）。
    # gcc / python3 / gnumake 是给 node-gyp 用的：像 dsh-better-sidebar 依赖的
    # node-pty 这类包要在安装时现场编译原生模块。它们只在 wrapper 的 PATH 上，
    # 不进全局环境（devtools.nix 里那个 nixpkgs 的 nodejs 24 与 dsh 无关）。
    runtimeInputs = with pkgs; [
      fnm
      coreutils
      pnpmOnly
      gcc
      python3
      gnumake
    ];

    text = ''
      # dsh 0.2.x 的宿主层（dsh-app-boot 的 installRuntimeInterception）用原生
      # node-addon-require-builtin 反汇编运行中 node 的机器码来定位 V8 getter，
      # 因此只认官方发布的 node 二进制；nixpkgs 自己编的 node 会以
      #   node-addon-require-builtin unsupported: Unsupported/no-getter
      #   (x64 sysv getter is not a recognized this->field accessor)
      # 硬失败（nodejs-slim-24.19.0 与 nodejs-26.8.2 都实测过）。所以 node 一律由
      # fnm 提供，不再看调用者 PATH 上是什么，见仓库 AGENTS.md 第 7 节。
      dsh_node="''${DSH_NODE_VERSION:-26}"

      if ! node_version_out="$(fnm exec --using="$dsh_node" -- node --version 2>&1)"; then
        echo "dsh: 无法通过 fnm 取得 Node $dsh_node，而 dsh 只认官方构建的 node。" >&2
        echo "     $node_version_out" >&2
        echo "     装一个官方版本：fnm install $dsh_node" >&2
        echo "     （也可用 DSH_NODE_VERSION 指定别的版本；详见仓库 AGENTS.md 第 7 节）" >&2
        exit 1
      fi

      # 官方 v26 是验证过的版本；别的官方版本未必不行，所以只提醒不拦。
      case "$node_version_out" in
        v2[6-9]* | v[3-9][0-9]*) ;;
        *) echo "dsh: 警告：fnm 给出的 node 是 $node_version_out，dsh 只在官方 Node 26 上验证过。" >&2 ;;
      esac

      # npx 与 runner 里的 node 都在这一个 fnm 上下文里解析，保证是同一个官方 node。
      exec fnm exec --using="$dsh_node" -- npx \
        --yes \
        --package=@deepseek-ai/dsh@0.2.0-rc.2 \
        -- ${dshRunner} "$@"
    '';
  };
in
{
  home.packages = [
    dsh
  ];

  home.sessionVariables = {
    DSH_HOME = "${config.xdg.dataHome}/deepseek-harness";
  };
}
