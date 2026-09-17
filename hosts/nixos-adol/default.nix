{ username, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/base.nix
      ../../modules/nixos/ssh.nix
      ../../modules/nixos/shell.nix
      ../../modules/nixos/fonts.nix
      ../../modules/nixos/icons.nix

      ../../modules/nixos/compat.nix
      ../../modules/nixos/niri.nix
      ../../modules/nixos/umbriel.nix
      ../../modules/nixos/noctalia.nix
      ../../modules/nixos/greetd.nix
      ../../modules/nixos/fcitx5.nix
      ../../modules/nixos/clash-verge.nix
      ../../modules/nixos/docker.nix
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
      "docker"
    ];
  };

  # 会话层面 dotfiles/niri/environment.kdl 把 LANG 设成了 zh_CN.UTF-8，但 NixOS 默认只生成
  # en_US.UTF-8 / C.UTF-8，那个 locale 一直不存在 —— foot 会明确警告
  # "invalid locale, falling back to 'C.UTF-8'"，其它程序则是静默退回 C。
  # 默认 LANG 保持 en_US.UTF-8（/etc/locale.conf），只把 zh_CN 加进支持的 locale 集合。
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "zh_CN.UTF-8/UTF-8" ];

  system.stateVersion = "26.05";
}
