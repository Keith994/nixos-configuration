{ pkgs, config, ... }:

let
  # 真正启动 dsh 的内部脚本。
  # 这个脚本是在 `npx --package=...` 创建好的环境里运行，
  # 此时 command -v dsh 会找到 npm 包里的 dsh。
  dshRunner = pkgs.writeShellScript "dsh-runner" ''
    entry="$(readlink -f "$(command -v dsh)")"

    exec node \
      --expose-internals \
      "$entry" \
      "$@"
  '';

  # `dsh plugin` 会把参数转发给 profile 目录里的 pnpm，pnpm 必须在 dsh 进程的
  # PATH 上。但 pkgs.pnpm 自己带一份 node，直接加进 runtimeInputs 会按 PATH 顺序
  # 遮蔽 nodejs_24（dsh 启动和 node-gyp 用的都得是 24），所以只暴露它的 bin。
  pnpmOnly = pkgs.symlinkJoin {
    name = "pnpm-only";
    paths = [ pkgs.pnpm ];
    postBuild = ''
      rm -f $out/bin/node $out/bin/npx $out/bin/corepack
    '';
  };

  dsh = pkgs.writeShellApplication {
    name = "dsh";

    # gcc / python3 / gnumake 是给 node-gyp 用的：像 dsh-better-sidebar 依赖的
    # node-pty 这类包要在安装时现场编译原生模块（见仓库 AGENTS.md 第 7 节）。
    # 只放进 wrapper，不污染全局环境（devtools.nix 里的 nodejs 不受影响）。
    runtimeInputs = with pkgs; [
      nodejs_24
      coreutils
      pnpmOnly
      gcc
      python3
      gnumake
    ];

    text = ''
      exec npx \
        --yes \
        --package=@deepseek-ai/dsh@0.1.5-rc.1 \
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
