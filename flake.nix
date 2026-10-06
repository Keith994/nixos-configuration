{
  description = "My Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # 只为**个别包**引入 unstable：clash-verge-rev（26.05 = 2.4.7，unstable = 2.5.2）和
    # wechat（26.05 = 4.1.1.4，unstable = 4.1.1.8）。
    # 刻意 **不加** inputs.nixpkgs.follows —— 加了就等于又换回 26.05 的包，等于没换。
    # 也刻意不把它用在系统上：outputs 里只 import 出一个独立实例 pkgsUnstable，
    # 取到的包自带它那份 GTK/WebKit 闭包，与系统 pkgs 并存，不会牵动全系统重新求值/重建。
    # 用 nixos-unstable 而不是 nixpkgs-unstable：这里只要包，不需要 NixOS 模块的测试集。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia 官方 flake：要的是 5.1.x 的包和 programs.noctalia 模块（含构建期 config validate）。
    # 刻意 **不加** inputs.nixpkgs.follows —— 官方 Cachix 缓存是按它自己的 nixpkgs 构建的，
    # 覆盖 nixpkgs 会改变 derivation hash 从而全部缓存失效（见 docs.noctalia.dev 的 Binary Cache）。
    # 用 cachix 分支而不是 main：永远指向 CI 已经缓存好的最新提交。
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # Zen Browser：锁定的 nixpkgs 26.05 里根本没有 zen-browser（pkgs/by-name/ze 下查无此项），
    # 只能走社区 flake。两个 follows 都要加：
    # - nixpkgs follows：Zen 是预编译二进制，靠 autoPatchelfHook 链系统库，库版本和系统错配会
    #   出现「没有 WebGL / 不认 GPU」这类问题（上游 README 的 troubleshooting 同样这么建议）；
    # - home-manager follows：它的 homeModules.* 会 import `${home-manager}/modules/programs/
    #   firefox/mkFirefoxModule.nix`，跟着我们这份 release-26.05 走，选项语义才不会和本地 HM 漂移。
    # 代价是它的包吃不到上游缓存，但 Zen 只是 repack 上游 tarball，本地构建很便宜。
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Umbriel：noctalia 官方的 wlroots 合成器。只作为 greetd 里的**额外可选测试会话**，
    # 不动 niri 主线（greetd.nix 的 session.default 仍然是 "niri"）。
    # 和 noctalia 一样刻意 **不加** inputs.nixpkgs.follows：上游 flake 自带 nixos-unstable pin，
    # 而 umbriel 要 wlroots 0.20.1+ / C++23，跟着本仓库的 nixos-26.05 混编风险更大；
    # 它没有 cachix 缓存，跟不跟 nixpkgs 都要本地编译（首次 switch 会编译 umbriel +
    # xdg-desktop-portal-umbriel，比较久）。接线在 modules/nixos/umbriel.nix，配置在 dotfiles/umbriel/。
    #
    # 用 git+https 而不是 github:（上游 README 也推荐这种写法）：github: 走 api.github.com
    # 解析分支，未认证限额只有 60 次/小时，共享出口 IP 一打满 `nix flake lock` 就 403；
    # git+https 走 git 协议，不碰那个接口。它自带的 portal 输入同理覆盖掉。
    umbriel = {
      url = "git+https://github.com/noctalia-dev/umbriel";
      inputs.xdg-desktop-portal-umbriel.url = "git+https://github.com/noctalia-dev/xdg-desktop-portal-umbriel";
    };

    # CachyOS 内核：Clang + ThinLTO、按 Zen4 编译（接线在 modules/nixos/kernel.nix）。
    # 刻意 **不加** inputs.nixpkgs.follows —— 上游 README 明确要求别覆盖它的 nixpkgs：
    # CachyOS 的补丁是按特定内核版本准备的，跟着本仓库的 nixos-26.05 走会版本错配，
    # 而且上游缓存里的产物（见 modules/nixos/base.nix）是按它自己那份 nixpkgs 构建的，
    # 改了就等于放弃缓存、本地编内核。
    # 用 release 分支而不是默认分支：release 永远指向 Hydra CI 已经构建完、缓存里有的提交。
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "keith";

      # 独立于系统 nixpkgs 的实例，目前服务两个包：clash-verge-rev（modules/nixos/clash-verge.nix）
      # 和 wechat（modules/home/wechat.nix）。模块要拿到它就分别走 specialArgs /
      # home-manager.extraSpecialArgs —— 两边都得传，别只传系统侧。
      # config 里只放行 wechat 这一个 unfree 名字：它是闭源二进制，不放行会直接求值失败；
      # 其余保持默认的 allowUnfree = false，这样将来再有 unfree 包进来是**构建报错**，
      # 而不是被系统那份白名单悄悄放行（别图省事写成 allowUnfree = true）。
      pkgsUnstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "wechat" ];
      };
    in
    {
      nixosConfigurations.nixos-adol =
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs username pkgsUnstable;
          };

          modules = [
            ./hosts/nixos-adol

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs username pkgsUnstable;
              };

              home-manager.users.${username} =
                import ./home/keith;
            }
          ];
        };
    };
}
