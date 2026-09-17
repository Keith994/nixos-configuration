{ pkgs, ... }:

{
  # 图形界面应用：没有 programs.* 模块的、也不需要额外包装参数的放这里。
  # 需要单独塞命令行参数 / 环境变量的（chrome、ghostty 之类）仍然各自建模块。
  home.packages = with pkgs; [
    # Electron 应用。niri 会话里已经有 NIXOS_OZONE_WL=1 和
    # ELECTRON_OZONE_PLATFORM_HINT=auto（modules/nixos/niri.nix），所以不用再包一层 wrapper。
    obsidian
    feishu

    # Emacs 同时提供 emacsclient，供 niri 的编辑器快捷键调用。
    emacs

    # Flutter/GTK 写的，原生 Wayland，不需要额外包装参数；可执行文件名是 localsend_app。
    # 局域网收文件要在 base.nix 放行 53317（TCP+UDP），否则只能发不能收。
    localsend

    # nixpkgs 的 telegram-desktop 是 Qt6 + qtwayland（wrapQtAppsHook 包装），
    # niri 的 XDG_SESSION_TYPE=wayland 会让 Qt 自己选 Wayland，不需要额外环境变量。
    # 可执行文件名是 Telegram（大写，meta.mainProgram），Wayland app-id 是
    # org.telegram.desktop；niri 里 Mod+T 走 scripts/switch.sh 聚焦/启动它。
    telegram-desktop
  ];
}
