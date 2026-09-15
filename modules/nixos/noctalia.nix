{ ... }:

{
  # noctalia 的 wifi / 蓝牙 / 电源模式 / 电池组件依赖这几个系统服务，缺了对应组件就是灰的。
  # networking.networkmanager 已经在 base.nix 开了。
  # power-profiles-daemon 与 tuned 二选一，本仓库没用 tuned。
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
}
