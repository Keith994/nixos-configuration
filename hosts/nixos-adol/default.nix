{ username, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/base.nix
      ../../modules/nixos/ssh.nix
      ../../modules/nixos/shell.nix
      ../../modules/nixos/fonts.nix

      ../../modules/nixos/compat.nix
      ../../modules/nixos/niri.nix
      ../../modules/nixos/dms.nix
      ../../modules/nixos/greetd.nix
      ../../modules/nixos/fcitx5.nix
    ];

  # UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adol";

  # 普通用户
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  system.stateVersion = "26.05";
}
