{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;

    # 用 Home Manager 的 Chromium 模块管理 Google Chrome
    package = pkgs.google-chrome;

    commandLineArgs = [
      # niri 下强制原生 Wayland
      "--ozone-platform=wayland"

      # fcitx5 / Rime Wayland 输入
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"
    ];
  };
}
