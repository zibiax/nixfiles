{ pkgs, ... }:

{
  networking.hostName = "nix-desktop";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;

  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    grim
    slurp
    swaybg
    waybar
  ];

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
