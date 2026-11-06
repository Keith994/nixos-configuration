{ pkgs, ... }:

let
  # 固定在 3.6b（nixpkgs 默认已到 3.7b）。只覆盖 version/src，
  # 3.6b 的 configure 同样支持 systemd/sixel/utempter/utf8proc，构建参数沿用上游。
  # 升级 = 改 version 和 fetchFromGitHub 的 tag，再重算 hash
  #   nix-prefetch-url --unpack https://github.com/tmux/tmux/archive/refs/tags/<ver>.tar.gz
  tmux = pkgs.tmux.overrideAttrs (old: {
    version = "3.6b";
    src = pkgs.fetchFromGitHub {
      owner = "tmux";
      repo = "tmux";
      tag = "3.6b";
      hash = "sha256-iW4K/OxSVpxVkyI5Dy6lzwVf/8nXyjcHtL76Ezmxavc=";
    };
  });
in
{
  programs.tmux = {
    enable = true;
    package = tmux;
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    extraConfig =
      builtins.readFile ../../dotfiles/tmux/tmux.conf;
  };

  # tmux.conf 的 status-right 直接调用 gitmux，插件（nerd-font-window-name）也从
  # $HOME/.config/tmux/ 下读自己的 yml。这两个文件走不了 builtins.readFile，
  # 必须显式链接，否则路径不存在、对应段落静默变空。
  home.packages = [ pkgs.gitmux ];

  xdg.configFile = {
    "tmux/.gitmux.conf".source = ../../dotfiles/tmux/.gitmux.conf;
    "tmux/tmux-nerd-font-window-name.yml".source =
      ../../dotfiles/tmux/tmux-nerd-font-window-name.yml;
  };
}
