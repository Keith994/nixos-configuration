{ username, ... }:

{
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/git.nix
    ../../modules/home/shell.nix
    ../../modules/home/starship.nix
    ../../modules/home/nvim.nix

    ../../modules/home/ghostty.nix
    ../../modules/home/foot.nix
    ../../modules/home/tmux.nix
    ../../modules/home/media.nix
    ../../modules/home/devtools.nix
    ../../modules/home/yazi.nix
    ../../modules/home/niri.nix
    ../../modules/home/umbriel.nix
    ../../modules/home/noctalia.nix
    ../../modules/home/rime.nix
    ../../modules/home/ai/deepseek-harness.nix
    ../../modules/home/browsers.nix
    ../../modules/home/apps.nix
    ../../modules/home/wechat.nix
    ../../modules/home/fontconfig.nix

    # 按用途分组的命令行工具（每个文件一个主题、里面若干包）。抓包那两个
    # （tcpdump / wireshark）不在这里：它们要 setcap wrapper + 用户组，
    # 属于系统层，见 modules/nixos/packet-capture.nix。
    ../../modules/home/edge.nix
    ../../modules/home/iot.nix
    ../../modules/home/network.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
