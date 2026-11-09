{ username, ... }:

{
  imports = [
    ../../modules/home/cli.nix
    # 终端的 `open`：按文件类型挑程序（文本进 nvim、图片 imv、音视频 mpv，其余走 xdg-open）。
    ../../modules/home/open.nix
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
    ../../modules/home/noctalia.nix
    ../../modules/home/rime.nix
    ../../modules/home/ai/deepseek-harness.nix
    ../../modules/home/ai/pi.nix
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

    # 两个数据库客户端，都因为 nixpkgs 里没有能直接用的包而各自建模块：
    #   dbeaver-ee.nix —— DBeaver **企业版** 26.1.0（闭源、要自己填 license key）。
    #     不能用 pkgs.dbeaver-bin：那个 derivation 的 url 写死了 CE 的 GitHub releases，
    #     而且版本是 26.2.0。EE 走 downloads.dbeaver.net/enterprise/<ver>/。
    #   sqlkit.nix —— SqlKit（Tauri 2 / Apache-2.0），nixpkgs 查无此包，解上游 deb。
    ../../modules/home/dbeaver-ee.nix
    ../../modules/home/sqlkit.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
