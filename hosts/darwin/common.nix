{ pkgs, ... }:

{
  networking.hostName = "nix-mac";
  time.timeZone = "Europe/Stockholm";

  services.nix-daemon.enable = true;
  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    ripgrep
  ];
}
