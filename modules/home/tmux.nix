{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
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
