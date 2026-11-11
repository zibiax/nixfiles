{
  description = "Lichii - experimental Switch / Switch 2 emulator (X11 by default)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Tracks the default branch; `nix flake update lichii-src` to bump.
    lichii-src = {
      url = "github:zortos293/Lichii/nx2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, lichii-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      version =
        let base = nixpkgs.lib.fileContents "${lichii-src}/VERSION";
        in "${base}-unstable-${builtins.substring 0 8 (lichii-src.lastModifiedDate or "19700101")}";
    in
    {
      packages = forAll (pkgs: rec {
        lichii = pkgs.callPackage ./package.nix {
          src = lichii-src;
          inherit version;
        };
        # Same build, but leaves Qt/SDL to pick Wayland when available.
        lichii-wayland = lichii.override { forceX11 = false; };
        default = lichii;
      });

      overlays.default = final: prev: {
        lichii = final.callPackage ./package.nix {
          src = lichii-src;
          inherit version;
        };
      };
    };
}
