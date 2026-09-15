{
  description = "My Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia 官方 flake：要的是 5.1.x 的包和 programs.noctalia 模块（含构建期 config validate）。
    # 刻意 **不加** inputs.nixpkgs.follows —— 官方 Cachix 缓存是按它自己的 nixpkgs 构建的，
    # 覆盖 nixpkgs 会改变 derivation hash 从而全部缓存失效（见 docs.noctalia.dev 的 Binary Cache）。
    # 用 cachix 分支而不是 main：永远指向 CI 已经缓存好的最新提交。
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
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
    in
    {
      nixosConfigurations.nixos-adol =
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs username;
          };

          modules = [
            ./hosts/nixos-adol

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs username;
              };

              home-manager.users.${username} =
                import ./home/keith;
            }
          ];
        };
    };
}
