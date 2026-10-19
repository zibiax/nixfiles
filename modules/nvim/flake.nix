{
  description = "zibiax neovim config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # `nix run .` or add `packages.default` to home.packages / environment.systemPackages
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./nix/neovim.nix { configDir = self; };
      });
    };
}
