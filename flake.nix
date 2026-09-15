{
  description = "My Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
