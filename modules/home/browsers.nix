{ inputs, pkgs, ... }:

{
  # 浏览器只有两个，共用同一套「强制原生 Wayland + 走 fcitx5 输入法」的诉求，
  # 所以放一个文件里。默认浏览器两边都**没**抢：chrome 这边是 HM 模块的默认值，
  # Zen 那边 setAsDefaultBrowser 也刻意没开；要改就 `xdg-mime default ...`。

  # Chrome 走 HM 的 programs.chromium（package 指到 google-chrome）。
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

  # nixpkgs 26.05 里没有 zen-browser 包，用的是 flake.nix 里那个社区 flake 的
  # programs.zen-browser 模块（它内部复用 HM 的 mkFirefoxModule，所以 profiles / policies /
  # settings / bookmarks 这些选项和 programs.firefox 是同一套写法）。
  # 想换通道就换成 homeModules.twilight（nightly，产物由该 flake 自己转存、不怕上游删档）
  # 或 homeModules.twilight-official（直接取 Zen 官方产物，但官方会覆盖旧文件导致 hash 失配）。
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # 装出来的命令是 zen-beta（不带 wrapper 的 zen 不要直接用）。
    # niri 下强制原生 Wayland；输入法不需要额外变量，modules/nixos/fcitx5.nix 的
    # waylandFrontend 已经让 Zen/GTK 走 text-input 协议。
    env.MOZ_ENABLE_WAYLAND = "1";

    # 自更新和遥测由模块 mkDefault 成 DisableAppUpdate / DisableTelemetry，不在这里重复。
  };
}
