{ lib, pkgs, ... }:

{
  networking.hostName = "nix-laptop";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.fwupd.enable = true;

  services.power-profiles-daemon.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
  services.logind.extraConfig = ''
    HandleLidSwitchExternalPower=suspend
    HandleLidSwitchDocked=ignore
  '';

  environment.systemPackages = with pkgs; [
    acpi
    powertop
  ];
}
