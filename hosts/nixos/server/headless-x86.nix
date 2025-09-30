{ lib, pkgs, user, ... }:

{
  networking.hostName = "nix-headless";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  services.qemuGuest.enable = lib.mkDefault true;
  virtualisation.docker.enable = true;
  users.groups.docker.members = [ user ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    lm_sensors
  ];

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
