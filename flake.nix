{{
  description = "Unified NixOS and macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        username = "lakrisal";
        hostname = "nixcomp";
      in
      {
        nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nixos/${hostname}.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/nixos.nix;
            }
          ];
        };

        darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/darwin/${hostname}.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/darwin.nix;
            }
          ];
        };
      });
}

