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
      defaultUser = "lakrisal";
      sharedHome = [ ./home/modules/common.nix ];
      linuxHomeShared = sharedHome ++ [ ./home/linux/common.nix ];
      serverHomeShared = sharedHome ++ [ ./home/server/common.nix ];
      darwinHomeShared = sharedHome ++ [ ./home/darwin/common.nix ];
      mkHomeConfig = user: shared: modulePath: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-bak";
        home-manager.extraSpecialArgs = { inherit inputs user; };
        home-manager.sharedModules = shared;
        home-manager.users.${user} = import modulePath;
      };
      mkNixos = { system ? "x86_64-linux", user ? defaultUser, homeShared, homeModule, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            ./hosts/nixos/common.nix
            inputs.agenix.nixosModules.default
            ./modules/secrets/linux-ssh-key.nix
            home-manager.nixosModules.home-manager
            (mkHomeConfig user homeShared homeModule)
          ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        # Main desktop (MSI B450 / Ryzen 7 5700X / RTX 2060), replaces the EndeavourOS install.
        desktop = mkNixos {
          user = "martin";
          homeShared = linuxHomeShared;
          homeModule = ./home/linux/desktop.nix;
          modules = [ ./hosts/nixos/desktop.nix ];
        };

        laptop = mkNixos {
          homeShared = linuxHomeShared;
          homeModule = ./home/linux/laptop.nix;
          modules = [ ./hosts/nixos/laptop.nix ];
        };

        headless-x86 = mkNixos {
          homeShared = serverHomeShared;
          homeModule = ./home/server/headless.nix;
          modules = [
            ./hosts/nixos/server/common.nix
            ./hosts/nixos/server/headless-x86.nix
          ];
        };

        raspberry-pi = mkNixos {
          system = "aarch64-linux";
          homeShared = serverHomeShared;
          homeModule = ./home/server/headless.nix;
          modules = [
            ./hosts/nixos/server/common.nix
            ./hosts/nixos/server/raspberry-pi.nix
          ];
        };
      };

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; user = defaultUser; };
          modules = [
            inputs.agenix.darwinModules.default
            ./hosts/darwin/common.nix
            ./hosts/darwin/macbook.nix
            home-manager.darwinModules.home-manager
            (mkHomeConfig defaultUser darwinHomeShared ./home/darwin/macbook.nix)
          ];
        };
      };

    }
    // flake-utils.lib.eachDefaultSystem (system: {
      packages.agenix = inputs.agenix.packages.${system}.default;
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    });
}
