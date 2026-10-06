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
    # CachyOS 内核（modules/nixos/kernel.nix）的缓存。上游 flake 自己在 nixConfig 里带了它的
    # 官方缓存，但 nixConfig **只在直接操作那个 flake 时生效**，作为本仓库的 input 时不会自动
    # 带上 —— 所以必须在这儿自己配一份。少了它，Clang+ThinLTO 的内核要在笔记本上本地编，很久。
    #
    # 这里用的是上游 README 列出的**备用镜像** cache.xinux.uz，而不是作者自己的
    # attic.xuyh0120.win —— 这一条差别是决定性的。本机实测：attic 只有走 clash 的 10800 才连得上、
    # **直连不通**，而 cache.xinux.uz / cache.nixos.org / noctalia.cachix.org 都**直连可达**。
    # 为什么这很关键：modules/home/shell.nix 里 nr/nb/nu/nup 的代理**只作用于客户端**（flake 输入
    # 抓取），而**下载 store 路径的是 nix-daemon**，它由 systemd 拉起、不继承任何 shell 变量
    # （DefaultEnvironment 为空、单元 Environment= 无 proxy、机器上没有 TUN）。挂 attic 就等于
    # 每次内核升级都要 root + 代理手工 `nix copy` 预取，漏了就退化成几小时本地编译；挂一个直连
    # 可达的镜像，daemon 自己就能下，没有任何手工步骤。
    #
    # 代价是信任方多一个：镜像的 narinfo 是**重新签名**的（整个文件只有 cache.xinux.uz 一条 Sig），
    # 所以信的是镜像维护者而不是上游 CI 作者；上游 README 也明确声明不保证这个缓存的安全与可用性。
    # 想换回作者自己的 attic（只信一把 key），得先让 daemon 够得到它：开 TUN，或给 daemon 配代理
    # （记得把 cache.nixos.org / cachix 放进 no_proxy，否则 clash 没起时连它们一起断）。
    #
    # 附带一条免得白折腾：`modules-shrunk` 那个 output **任何公共缓存里都不会有** —— 它依赖本机的
    # rootModules，逐机不同。但它只是纯 shell 后处理（modules-closure.sh：按 rootModules 挑模块 +
    # 拷固件 + `depmod -a`），几分钟的活，**不是编译**，所以内核那几百 MB 下完之后本地很快就会结束。
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://cache.xinux.uz"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
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
