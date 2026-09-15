{ pkgs, ... }:

{
  # 图形界面应用：没有 programs.* 模块的、也不需要额外包装参数的放这里。
  # 需要单独塞命令行参数 / 环境变量的（chrome、ghostty 之类）仍然各自建模块。
  home.packages = with pkgs; [
    # Electron 应用。niri 会话里已经有 NIXOS_OZONE_WL=1 和
    # ELECTRON_OZONE_PLATFORM_HINT=auto（modules/nixos/niri.nix），所以不用再包一层 wrapper。
    obsidian
  ];
}
