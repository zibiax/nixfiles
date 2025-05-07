{ pkgs, ... }:

{
  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
