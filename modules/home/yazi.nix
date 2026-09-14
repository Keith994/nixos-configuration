{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    extraPackages = with pkgs; [
      ffmpegthumbnailer
      jq
      poppler
      fd
      ripgrep
      fzf
      zoxide
      imagemagick
    ];
  };
  xdg.configFile."yazi" = {
    source = ../../dotfiles/yazi;
    recursive = true;
  };
}
