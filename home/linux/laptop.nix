{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    networkmanagerapplet
    quickshell
    swaybg
    powertop
    ydotool
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
  };

  services.mako.enable = true;

  home.file.".config/hypr" = {
    source = ../../modules/hypr;
    recursive = true;
  };

  home.file.".config/quickshell" = {
    source = ../../modules/quickshell;
    recursive = true;
  };

  # relaunch.sh (run by hyprland) starts quickshell and swaybg with a random wallpaper.
  home.file.".local/scripts".source = ../../modules/scripts/local;
  home.file."Pictures/Wallpapers".source = ../../wallpapers;

  # Icon font used by quickshell.
  home.file.".local/share/fonts/Feather.ttf".source = ../../modules/fonts/Feather.ttf;
}
