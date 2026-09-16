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
    ../../modules/home/mpv.nix
    ../../modules/home/imv.nix
    ../../modules/home/satty.nix
    ../../modules/home/devtools.nix
    ../../modules/home/yazi.nix
    ../../modules/home/niri.nix
    ../../modules/home/noctalia.nix
    ../../modules/home/rime.nix
    ../../modules/home/ai/deepseek-harness.nix
    ../../modules/home/chrome.nix
    ../../modules/home/zen.nix
    ../../modules/home/apps.nix
    ../../modules/home/fontconfig.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
