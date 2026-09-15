{ config, lib, pkgs, username, ... }:

let
  # greeter 只读 /var/lib/noctalia-greeter/greeter.toml 这个固定路径（没有 --config 之类的入口），
  # 所以配置用 tmpfiles 的 "L+" 软链进 store，每次 activation 重新指向。
  greeterConfig = (pkgs.formats.toml { }).generate "greeter.toml" {
    # 会话名按 picker 标签做大小写不敏感匹配（niri.desktop 的 Name=Niri）
    session.default = "niri";

    # 启动时直接进入该账户的密码步骤，省掉选用户
    user.default = username;

    cursor = {
      theme = "Adwaita";
      size = 24;
    };

    # 和 niri 的 xkb layout 保持一致
    keyboard.layout = "us";
  };

  # 包一层脚本而不是直接跑 noctalia-greeter-session，原因有两个：
  #   1. greeter 靠 XDG_DATA_DIRS 找 *.desktop 会话，而 greetd 服务自身环境里没有这个变量 ——
  #      NixOS 只把它写进 /etc/set-environment 供登录后的用户会话使用，niri.desktop 也只会出现在
  #      displayManager.sessionData 里，不在 /run/current-system/sw/share/wayland-sessions。
  #   2. session 包装脚本用 `command -v dbus-run-session` 起会话总线，greetd 服务默认 PATH 里没有 dbus。
  # 这两个变量只改 greeter 自己的进程树，greetd 之后拉起的用户会话不受影响。
  greeterSession = pkgs.writeShellApplication {
    name = "noctalia-greeter-start";
    runtimeInputs = [ pkgs.dbus ];
    text = ''
      export XDG_DATA_DIRS="${config.services.displayManager.sessionData.desktops}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
      exec ${lib.getExe' pkgs.noctalia-greeter "noctalia-greeter-session"} "$@"
    '';
  };
in

{
  services.greetd = {
    enable = true;

    settings.default_session = {
      # NixOS 的 greetd 模块会自己建 greeter 用户/组
      user = "greeter";
      command = "${greeterSession}/bin/noctalia-greeter-start";
    };
  };

  # greeter 靠 AccountsService 拿用户列表/头像；polkit 供 pkexec 提权（shell 里“同步外观到 greeter”用）
  services.accounts-daemon.enable = true;
  security.polkit.enable = true;

  # 必须进 system 包：外观同步的 helper 只接受 root 所有、且路径链不可被用户写的位置
  environment.systemPackages = [ pkgs.noctalia-greeter ];

  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };

    "/var/lib/noctalia-greeter/greeter.toml"."L+" = {
      # tmpfiles 的 argument 类型是 string，所以要插值成路径字符串（不能直接给 derivation）
      argument = "${greeterConfig}";
      user = "greeter";
      group = "greeter";
    };
  };
}
