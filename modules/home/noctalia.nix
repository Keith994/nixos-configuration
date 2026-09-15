{ inputs, ... }:

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

    # 不用 systemd user service：niri 的 startup.kdl 里 spawn-at-startup "noctalia" 就够了
    # （用服务的话要另开 launch_apps_as_systemd_services，否则重启服务会带走它启动的程序）
    systemd.enable = false;
  };
}
