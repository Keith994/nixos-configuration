{ inputs, config, pkgs, ... }:

let
  # 只让 noctalia 自己走代理：它要拉天气 / Wallhaven 这类外网 API，而 clash-verge 没开
  # 系统代理（verge.yaml 里 enable_system_proxy = false、enable_tun_mode = false），
  # 所以需要外网的程序必须自己指向 mixed-port。端口取值同 clash-verge-rev 的
  # config.yaml `mixed-port` 与 modules/home/shell.nix 里的 vpn 别名 —— 改端口要一起改。
  proxy = "http://127.0.0.1:10800";
  socksProxy = "socks5://127.0.0.1:10800";

  # 特意做成 wrapper，而不是在 dotfiles/niri/environment.kdl 里给整个 niri 会话导出，
  # 也不是写进全局环境：niri 及其它 spawn-at-startup 项（clash-verge / foot / fcitx5）
  # 都不带代理变量，只有 noctalia 进程树带。
  # 已知代价：noctalia 的子进程会继承，所以从 noctalia launcher 里启动的程序也会走代理。
  noctalia-proxy = pkgs.writeShellScriptBin "noctalia-proxy" ''
    export HTTP_PROXY=${proxy}
    export HTTPS_PROXY=${proxy}
    export ALL_PROXY=${socksProxy}
    export http_proxy="$HTTP_PROXY"
    export https_proxy="$HTTPS_PROXY"
    export all_proxy="$ALL_PROXY"

    # 本机与局域网流量绕过代理，取值与 environment.kdl 里注释掉的那份保持一致
    export NO_PROXY="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
    export no_proxy="$NO_PROXY"

    exec ${config.programs.noctalia.package}/bin/noctalia "$@"
  '';
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # 用上游模块而不是手写 xdg.configFile：模块会把 dotfiles 里那份 TOML 软链成
  # ~/.config/noctalia/config.toml，并在构建期跑 `noctalia config validate` —— 键名写错会在 rebuild 时直接报错。
  # 配置目录仍然是只读的：GUI/IPC 的改动写 ~/.local/state/noctalia/settings.toml，优先级更高。
  programs.noctalia = {
    enable = true;

    # 直接吃仓库里的文件，保持「配置落在 dotfiles/」的约定（模块也接受 attrset / TOML 字符串）
    settings = ../../dotfiles/noctalia/config.toml;

    # 默认值，写出来是因为它正是这套配置的价值所在
    checkConfig = true;

    # 不用 systemd user service：niri 的 startup.kdl 里 spawn-at-startup "noctalia-proxy" 就够了
    # （用服务的话要另开 launch_apps_as_systemd_services，否则重启服务会带走它启动的程序）
    systemd.enable = false;
  };

  # dotfiles/niri/startup.kdl 启动的是 noctalia-proxy（带代理变量的 wrapper），不是 noctalia
  home.packages = [ noctalia-proxy ];
}
