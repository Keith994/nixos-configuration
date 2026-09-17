{ config, lib, pkgsUnstable, username, ... }:

{
  # clash-verge-rev 的官方 NixOS 模块（nixpkgs 里 programs.clash-verge 默认就是它）。
  # niri 的 startup.kdl 会 spawn `clash-verge` 拉起 GUI，所以不启用 autoStart，避免重复启动。
  programs.clash-verge = {
    enable = true;

    # 只把**包**换成 unstable（26.05 = 2.4.7 → unstable = 2.5.2）；模块本身仍是 26.05 的。
    # package 选项两个分支都有，所以这只是一次值覆盖，不涉及模块结构差异。
    # pkgsUnstable 来自 flake.nix 的第二个 nixpkgs input（见 AGENTS.md 第 8 节第 17 条）。
    package = pkgsUnstable.clash-verge-rev;

    # serviceMode：起一个 root 常驻的 clash-verge-service，由它做 TUN 和端口转发。
    # 不走 tunMode（setcap）那条路，因为模块注释明说那样 DNS 设置不生效。
    serviceMode = true;

    # 服务 socket 归这个组，只有组内用户能连；单用户机器上也比默认的 users 更收敛。
    group = "clash-verge";
  };

  # unstable 的服务端（clash-verge-service-ipc 2.3.3）需要一块可写的 state 目录，而 26.05 的
  # 模块没声明 StateDirectory；ProtectSystem = "strict" 下 /var 只读，服务会写盘失败。
  # IPC socket 本身不受影响：两版都走模块已有的 RuntimeDirectory
  # （/run/clash-verge-rev/service.sock）。用 mkIf 守住整个 unit，避免 serviceMode 关掉时
  # 凭空定义一个没有 ExecStart 的服务。
  systemd.services.clash-verge = lib.mkIf config.programs.clash-verge.serviceMode {
    serviceConfig.StateDirectory = "clash-verge-service";
  };

  users.groups.clash-verge = { };

  # 不加进组的话 GUI 连不上 service socket，serviceMode 会退化成普通模式。
  users.users.${username}.extraGroups = [ "clash-verge" ];
}
