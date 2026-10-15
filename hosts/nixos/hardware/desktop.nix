# Hardware config for the desktop (MSI MS-7C37 / Ryzen 7 5700X / RTX 2060).
#
# This is a hand-written stand-in. During the NixOS install, after partitioning
# and mounting, run `nixos-generate-config --root /mnt` and REPLACE this file
# with the generated /mnt/etc/nixos/hardware-configuration.nix -- the root and
# boot UUIDs below are from the old EndeavourOS install and will change when
# the NVMe is reformatted.
#
# The data drives (Vault/Backup/Big) live in hosts/nixos/desktop.nix since
# they are on separate disks and keep their UUIDs across the reinstall.
{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/caefd2f0-9dee-4792-b854-ff9a247c890e"; # REPLACE after reinstall
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B298-B3CD"; # REPLACE after reinstall
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
