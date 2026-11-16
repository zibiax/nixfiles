{
  description = "Helium browser, repackaged from the official prebuilt Linux release";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        helium = pkgs.callPackage ./package.nix { };
        default = helium;
      });

      overlays.default = final: prev: {
        helium = final.callPackage ./package.nix { };
      };
    };
}
