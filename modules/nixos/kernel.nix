{ inputs, pkgs, ... }:

{
  # CachyOS 内核：Clang + ThinLTO，并按 Zen4 编译。8945H 是 Zen4（family 25），
  # 所以 -zen4 这一档是真吃得到，不是摆设。
  #
  # 用 overlays.pinned 而**不是** overlays.default：pinned 只往 pkgs 里多塞一个
  # cachyosKernels 属性（内核本身来自上游 pin 的 nixos-unstable-small），并不替换本仓库的
  # nixpkgs —— 所以 home-manager 26.05 / noctalia / umbriel 的 pin 一个都不动，也不会全系统重编。
  # default 会拿我们自己的 nixpkgs 去编内核，而缓存里的产物（见 base.nix）是按它自己那份 nixpkgs
  # 构建的，hash 一旦对不上就得在笔记本上本地跑 Clang+ThinLTO 编内核。
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # 升级内核 = `nix flake update nix-cachyos-kernel`（不带参数的 nix flake update 也会带上它）。
  # 内核版本从此不再跟 nixpkgs 26.05 走，而是跟上上游 release 分支，这是刻意的。
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

  # 显式写出来是为了把 active 模式钉住：实测本机 /proc/cmdline 里本来没有这个参数，
  # 而 amd_pstate/status 已经是 active、scaling_driver 是 amd-pstate-epp —— 也就是说
  # 内核 6.18 的默认值就是它。但 CachyOS 的内核 config 自带 CONFIG_AMD_PSTATE_DEFAULT_MODE，
  # 换内核时默认值有可能变，显式声明免得哪天悄悄滑回 passive/guided。
  #
  # 刻意**不**加 amd_pstate=passive / guided、amd_prefcore=disable、amd_dynamic_epp=enable；
  # 也刻意不上 SCX / BORE / BMQ / RT 和常驻 performance governor —— 这台机器是日常 + 开发，
  # 要的是吞吐、稳定、空闲省电，不是游戏调度延迟。EPP 的切换交给 power-profiles-daemon
  # （modules/nixos/noctalia.nix）：日常 balanced、长时间编译再手动 performance。
  boot.kernelParams = [ "amd_pstate=active" ];

  # 将来若要加 out-of-tree 模块（zfs / nvidia / virtualbox / vmware）：上游 packages.nix 已经
  # 对所有 linuxPackages-* 套好了 kernelModuleLLVMOverride（LTO 内核编外部模块必需），
  # 连 vbox / vmware 的 makeFlags 和 nvidia open 的补丁都补了，所以能编，只是会拖长 switch。
  # 本机现在 boot.extraModulePackages = [ ]、vmware.nix 也没被 import，故眼下无影响。
}
