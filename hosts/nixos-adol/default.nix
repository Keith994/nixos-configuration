{ username, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/base.nix
      ../../modules/nixos/kernel.nix
      ../../modules/nixos/ssh.nix
      ../../modules/nixos/shell.nix
      ../../modules/nixos/fonts.nix
      ../../modules/nixos/icons.nix

      ../../modules/nixos/compat.nix
      ../../modules/nixos/niri.nix
      ../../modules/nixos/noctalia.nix
      ../../modules/nixos/greetd.nix
      ../../modules/nixos/fcitx5.nix
      ../../modules/nixos/ollama.nix
      ../../modules/nixos/docker.nix
      ../../modules/nixos/packet-capture.nix
      ../../modules/nixos/vmware-host.nix
    ];

  # UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adol";

  # DBeaver 遥测屏蔽和内网服务域名映射都放在仓库外的 ~/.config/nixos/extra-hosts：
  # 仓库是公开的，内网域名 / IP 不能入库。flake 纯求值禁止读仓库外的绝对路径，
  # 所以对应命令都要带 --impure（nr / nb / nc / nup 已加）。文件缺失会直接 eval 失败，
  # 新机器先 `touch ~/.config/nixos/extra-hosts`。
  networking.extraHosts = builtins.readFile /home/keith/.config/nixos/extra-hosts;

  # 普通用户
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"

      # 抓包免 sudo：tcpdump 的 setcap wrapper 只对 pcap 组开放，
      # wireshark 的 dumpcap 只对 wireshark 组开放（两个组由
      # modules/nixos/packet-capture.nix 创建）。不进组就只能 sudo 抓。
      "pcap"
      "wireshark"
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
