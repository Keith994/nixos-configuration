{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    extraConfig =
      builtins.readFile ../../dotfiles/tmux/tmux.conf;
  };
}
