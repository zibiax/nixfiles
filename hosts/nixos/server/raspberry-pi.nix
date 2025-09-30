{ lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  networking.hostName = "nix-pi";

  boot.loader.grub.enable = false;
  boot.loader.genericExtlinuxCompatible.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = false;

  sdImage.compressImage = false;

  environment.systemPackages = with pkgs; [
    vim
    usbutils
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
