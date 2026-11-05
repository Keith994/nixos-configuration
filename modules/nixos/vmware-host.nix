{ ... }:

{
  # VMware Workstation 宿主：在这台机器上跑虚拟机。
  # 和 modules/nixos/vmware.nix 不是一回事 —— 那个是 guest（反过来在 VMware 里跑 NixOS），
  # 当前没有被任何 host import。
  virtualisation.vmware.host.enable = true;

  # vmware-vmx 在透明大页开启时会持续唤醒 kcompactd0（模块文档明确点出的问题），
  # 表现为宿主机空转时也有一核偏高，所以把 THP 关掉。
  boot.kernelParams = [ "transparent_hugepage=never" ];
}
