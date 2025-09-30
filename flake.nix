{
  description = "Unified NixOS, macOS, and server configuration";

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
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nixos-hardware, agenix, flake-utils, ... }:
    let
      user = "lakrisal";
      sharedHome = [ ./home/modules/common.nix ];
      linuxHomeShared = sharedHome ++ [ ./home/linux/common.nix ];
      serverHomeShared = sharedHome ++ [ ./home/server/common.nix ];
      darwinHomeShared = sharedHome ++ [ ./home/darwin/common.nix ];
      mkHomeConfig = shared: modulePath: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = shared;
        home-manager.users.${user} = import modulePath;
      };
      linuxBaseModules extra = [
        ./hosts/nixos/common.nix
      ] ++ extra;
    in
    {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user; };
          modules = linuxBaseModules [
            inputs.agenix.nixosModules.default
            ./hosts/nixos/desktop.nix
            ./modules/secrets/linux-ssh-key.nix
            home-manager.nixosModules.home-manager
            (mkHomeConfig linuxHomeShared ./home/linux/desktop.nix)
          ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user; };
          modules = linuxBaseModules [
            inputs.agenix.nixosModules.default
            ./hosts/nixos/laptop.nix
            ./modules/secrets/linux-ssh-key.nix
            home-manager.nixosModules.home-manager
            (mkHomeConfig linuxHomeShared ./home/linux/laptop.nix)
          ];
        };

        headless-x86 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user; };
          modules = linuxBaseModules [
            inputs.agenix.nixosModules.default
            ./hosts/nixos/server/common.nix
            ./hosts/nixos/server/headless-x86.nix
            ./modules/secrets/linux-ssh-key.nix
            home-manager.nixosModules.home-manager
            (mkHomeConfig serverHomeShared ./home/server/headless.nix)
          ];
        };

        raspberry-pi = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs user; };
          modules = linuxBaseModules [
            inputs.agenix.nixosModules.default
            ./hosts/nixos/server/common.nix
            ./hosts/nixos/server/raspberry-pi.nix
            ./modules/secrets/linux-ssh-key.nix
            home-manager.nixosModules.home-manager
            (mkHomeConfig serverHomeShared ./home/server/headless.nix)
          ];
        };
      };

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs user; };
          modules = [
            inputs.agenix.darwinModules.default
            ./hosts/darwin/common.nix
            ./hosts/darwin/macbook.nix
            home-manager.darwinModules.home-manager
            (mkHomeConfig darwinHomeShared ./home/darwin/macbook.nix)
          ];
        };
      };

      packages = flake-utils.lib.eachDefaultSystem (system: {
        agenix = inputs.agenix.packages.${system}.default;
      });

      formatter = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.alejandra);
    };
}
