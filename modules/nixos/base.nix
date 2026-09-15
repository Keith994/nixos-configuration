{ lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

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
    ];
}
