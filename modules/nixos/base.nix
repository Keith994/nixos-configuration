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

  zramSwap.enable = true;

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
