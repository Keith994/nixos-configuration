{ pkgs, pkgsUnstable, ... }:

let
  # 微信单独一个模块、而不是扔进 apps.nix：它要往启动环境里塞变量（apps.nix 的定位是
  # "没有 programs.* 模块、也不需要额外包装参数"的 GUI 应用）。
  #
  # 为什么要塞：这个 AppImage 里根本没有 Qt 动态库（readelf -d opt/wechat/wechat 没有任何
  # libQt*），Qt 和 fcitx 的 platforminputcontext 插件全是**静态**编进主程序的
  # （strings 里能查到 QFcitxPlatformInputContextPlugin）。静态插件只在 QT_IM_MODULE
  # 指到它时才会启用，而这个变量谁都没设 —— 会话里只有 dotfiles/niri/environment.kdl 的
  # XMODIFIERS=@im=fcitx（XIM），实测对微信无效，于是中文一个都打不进去。
  # 排查细节记在 AGENTS.md 第 8 节第 19 条。
  #
  # 只包微信这一层、不动会话级变量：fcitx5 是 waylandFrontend = true，其它 Qt/GTK 应用
  # 靠 text-input / input-method 协议，全局设 QT_IM_MODULE 反而会让它们绕开 Wayland 前端
  # （理由写在 dotfiles/niri/environment.kdl 的注释里，别去改那边）。
  #
  # 用 symlinkJoin 而不是 writeShellScriptBin：desktop 文件、图标都留在包里，
  # share/applications/wechat.desktop 的 Exec 是裸的 `wechat`，靠 PATH 命中这个 wrapper。
  #
  # 包取自 unstable（26.05 = 4.1.1.4，unstable = 4.1.1.8）；放行 unfree 的 predicate 在
  # flake.nix 里跟着 pkgsUnstable 走，所以 base.nix 的白名单里不再需要 "wechat"。
  wechat = pkgs.symlinkJoin {
    name = "wechat-ime";

    paths = [ pkgsUnstable.wechat ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/wechat --set QT_IM_MODULE fcitx
    '';
  };
in
{
  home.packages = [ wechat ];
}
