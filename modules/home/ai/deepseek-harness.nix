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

  dsh = pkgs.writeShellApplication {
    name = "dsh";

    runtimeInputs = with pkgs; [
      nodejs_24
      coreutils
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
