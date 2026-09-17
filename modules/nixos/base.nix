{ lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  # LocalSend 是局域网直连：TCP 53317 传文件、UDP 53317 做组播发现。
  # 防火墙默认全拦，不放行这两个端口时对方找不到本机、只能发不能收。
  # 组播发现还有问题的话再加 networking.firewall.checkReversePath = "loose";
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  time.timeZone = "Asia/Shanghai";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # noctalia 官方 Cachix（包里没有 nix cache 的构建）：不加这两行，inputs.noctalia 的包就得本地编译。
    # 注意：一旦给不支持的 substituter 签名，nix 会直接接受它下的包，所以 key 要照官方文档抄。
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  # 系统里唯一的 swap 就是这块 zram（内存里压缩出来的块设备）：本机磁盘上没有 swap 分区，
  # hardware-configuration.nix 的 swapDevices = [ ] —— 所以 free 里那 15Gi 交换全是它。
  # DiskSize 默认 = 50% 物理内存、zstd、priority 5；它不预留内存（空闲只占 ~20KB 内核内存），
  # 真实容量受物理内存限制（zstd 一般 2.5~3.5:1，全填满约吃 5Gi），作用是吸收内存尖峰、
  # 推迟 OOM，而不是"多出来一块内存"。代价见 AGENTS.md 第 8 节第 18 条：**不能休眠**。
  zramSwap.enable = true;

  # zram 场景的配套调优：压缩一页内存比丢一页 page cache 划算，而默认的 60 是"尽量别用 swap"
  # 时代的取值，会让内核倾向丢弃文件缓存、反而不去压冷匿名页，等于把 zram 闲置着。
  boot.kernel.sysctl."vm.swappiness" = 100;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
  # obsidian 也是 unfree（闭源 Electron 应用），加包时别忘了同步这个白名单。
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "obsidian"
      "feishu"
    ];
}
