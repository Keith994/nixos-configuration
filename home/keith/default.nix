{ username, ... }:

{
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/git.nix
    ../../modules/home/shell.nix
    ../../modules/home/starship.nix
    ../../modules/home/nvim.nix

    ../../modules/home/ghostty.nix
    ../../modules/home/tmux.nix
    ../../modules/home/devtools.nix
    ../../modules/home/yazi.nix
    ../../modules/home/niri.nix
    ../../modules/home/rime.nix
    ../../modules/home/ai/deepseek-harness.nix
    ../../modules/home/chrome.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
