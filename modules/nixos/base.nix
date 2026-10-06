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
    #
    # attic.lantian 是 CachyOS 内核（modules/nixos/kernel.nix）的缓存。上游 flake 自己在 nixConfig
    # 里带了这两行，但 nixConfig **只在直接操作那个 flake 时生效**，作为本仓库的 input 时不会自动
    # 带上 —— 所以必须在这儿照抄一遍。少了它，Clang+ThinLTO 的内核要在笔记本上本地编，很久。
    #
    # ⚠️ 本机实测：attic 只有走 clash 的 10800 才连得上，**直连不通**；而 cache.nixos.org 和
    # noctalia.cachix.org 都是直连可达的。modules/home/shell.nix 里 nr/nb/nup 的代理只作用于
    # **客户端**（flake 输入抓取），而**下载 store 路径的是 nix-daemon**、它由 systemd 拉起、
    # 不继承任何 shell 变量 —— 那儿"sudo env 够用"的结论，前提正是"缓存直连可达"，attic 是第一个
    # 打破这个前提的 substituter。所以这两行在**下载内核**这件事上代理不到它，内核要靠 root + 代理
    # 手工预取（nix copy 是客户端下载，代理有效）：
    #
    #   OUT=$(nix eval --raw .#nixosConfigurations.nixos-adol.config.boot.kernelPackages.kernel)
    #   sudo env https_proxy=http://127.0.0.1:10800 nix copy \
    #     --from https://attic.xuyh0120.win/lantian \
    #     --extra-trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" "$OUT"
    #
    # 每次 `nix flake update nix-cachyos-kernel` 之后都要重做一次，否则会退化成几小时的本地
    # Clang+ThinLTO 编译。留着这两行的意义：这次 switch 之后 lantian 就成为受信 key（以后 copy
    # 不必再写 --extra-trusted-public-keys），以及将来网络变了（比如开了 TUN）能自动生效。
    # 上游 README 那句"先切一次让缓存生效再开内核"解决的是 daemon **认不认识**这个缓存，
    # 解决不了**连不连得上**。
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
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
  # obsidian / feishu 也是 unfree（闭源 Electron 应用），加包时别忘了同步这个白名单。
  # wechat 曾经也在这个表里：现在它取自 pkgsUnstable（modules/home/wechat.nix），
  # 那份 unfree 放行跟着 flake.nix 里的 pkgsUnstable.config 走，别在这儿重复加。
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "obsidian"
      "feishu"
    ];
}
