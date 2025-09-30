{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    networkmanagerapplet
    powertop
    ydotool
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
  };

  programs.waybar.enable = true;
  services.mako.enable = true;

  home.file.".config/hypr" = {
    source = ../../modules/hypr;
    recursive = true;
  };

  home.file.".config/waybar" = {
    source = ../../modules/waybar;
    recursive = true;
  };
}
