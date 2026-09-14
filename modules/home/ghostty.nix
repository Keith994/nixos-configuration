{ config, ... }:

{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/ghostty/config";
}
