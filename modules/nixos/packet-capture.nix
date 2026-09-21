{ pkgs, ... }:

{
  # 抓包工具要特权，所以这两个放在系统层：直接在 home.packages 里装 pkgs.tcpdump /
  # pkgs.wireshark 是抓不到包的（非 root 开网卡会被拒），必须走 setcap wrapper。
  # 两个 wrapper 各自只对自己那个组开放，用户进组才能免 sudo —— 组在
  # hosts/nixos-adol/default.nix 的 extraGroups 里加。和 modules/nixos/docker.nix
  # 是同一类做法（装包 + 建组 + 挂特权）。

  # tcpdump：wrapper 挂 cap_net_raw，属组 pcap。
  programs.tcpdump.enable = true;

  # wireshark：GUI 本身不要特权，真正要特权的是 dumpcap —— 模块给它挂
  # cap_net_raw,cap_net_admin，属组 wireshark。
  # package 显式指到 pkgs.wireshark：模块默认装的是 wireshark-cli（只有 tshark /
  # dumpcap，没有界面），这里要的是 GUI（tshark 也一并带着）。
  # usbmon 保持默认关：那是抓 USB 流量的 udev 规则，本机用不到。
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
}
