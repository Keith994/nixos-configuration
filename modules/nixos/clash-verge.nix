{ username, ... }:

{
  # clash-verge-rev 的官方 NixOS 模块（nixpkgs 里 programs.clash-verge 默认就是它）。
  # niri 的 startup.kdl 会 spawn `clash-verge` 拉起 GUI，所以不启用 autoStart，避免重复启动。
  programs.clash-verge = {
    enable = true;

    # serviceMode：起一个 root 常驻的 clash-verge-service，由它做 TUN 和端口转发。
    # 不走 tunMode（setcap）那条路，因为模块注释明说那样 DNS 设置不生效。
    serviceMode = true;

    # 服务 socket 归这个组，只有组内用户能连；单用户机器上也比默认的 users 更收敛。
    group = "clash-verge";
  };

  users.groups.clash-verge = { };

  # 不加进组的话 GUI 连不上 service socket，serviceMode 会退化成普通模式。
  users.users.${username}.extraGroups = [ "clash-verge" ];
}
