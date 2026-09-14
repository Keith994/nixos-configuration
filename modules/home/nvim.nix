{ config, pkgs, ... }:

{
  # EDITOR
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # vi/vim -> nvim
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  home.packages = with pkgs; [
    ripgrep
    fd

    gcc
    gnumake

    curl
    wget
    unzip
  ];

  # ~/.config/nvim
  #       ↓
  # ~/nix-config/dotfiles/nvim
  #
  # 使用 out-of-store symlink，
  # 修改 Lua 后不需要 nixos-rebuild。
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/nvim";

}
