{ pkgs, pkgsUnstable, ... }:

{
  # 图形界面应用：没有 programs.* 模块的、也不需要额外包装参数的放这里。
  # 需要单独塞命令行参数 / 环境变量的（chrome、ghostty 之类）仍然各自建模块。
  home.packages = with pkgs; [
    # Electron 应用。niri 会话里已经有 NIXOS_OZONE_WL=1 和
    # ELECTRON_OZONE_PLATFORM_HINT=auto（modules/nixos/niri.nix），所以不用再包一层 wrapper。
    obsidian
    feishu

    # Emacs 同时提供 emacsclient，供 niri 的编辑器快捷键调用。
    pkgsUnstable.emacs-pgtk

    # Flutter/GTK 写的，原生 Wayland，不需要额外包装参数；可执行文件名是 localsend_app。
    # 局域网收文件要在 base.nix 放行 53317（TCP+UDP），否则只能发不能收。
    localsend

    # nixpkgs 的 telegram-desktop 是 Qt6 + qtwayland（wrapQtAppsHook 包装），
    # niri 的 XDG_SESSION_TYPE=wayland 会让 Qt 自己选 Wayland，不需要额外环境变量。
    # 可执行文件名是 Telegram（大写，meta.mainProgram），Wayland app-id 是
    # org.telegram.desktop；niri 里 Mod+T 走 scripts/switch.sh 聚焦/启动它。
    telegram-desktop

    # sing-box 的图形壳（GUI.for.SingBox，Vue3 + Wails/WebKitGTK）。四点要注意：
    # 1) **包必须取 unstable**（跟 wechat / clash-verge 同一套姿势）：26.05 里 pin 的是
    #    1.23.2，而上游已经把 `v1.23.2` 这个 tag 删了（`git/ref/tags/v1.23.2` → 404），
    #    fetchFromGitHub 永久失败，rebuild 会停在 "cannot download source from any mirror"。
    #    unstable 现在是 1.27.0，tag 还在。
    # 2) nixpkgs 这个包只给壳，sing-box 内核由 GUI 运行时自己下载到
    #    ~/.config/GUI.for.SingBox/（上游给 Linux 打了 XDG 路径补丁，数据/内核都落在
    #    配置目录而不是 store），所以第一次启动需要能连上 GitHub 拉内核。
    # 3) 它不在 cache.nixos.org 上（meta.hydraPlatforms = [ ]），首次 rebuild 要本地编
    #    pnpm 前端 + Go/wails，很慢（是编译，不是下载，别指望换镜像能加速）。
    # 4) GTK/WebKit 原生 Wayland，不需要额外包装参数。
    pkgsUnstable.gui-for-singbox

    # wechat 不在这里：它要用 unstable 的包、还得单独塞 QT_IM_MODULE（不塞就一个中文都
    # 打不进去），见 modules/home/wechat.nix。
  ];
}
