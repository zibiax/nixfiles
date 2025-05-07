{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "z" ];
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      # Add your Alacritty settings here
    };
  };

  programs.waybar = {
    enable = true;
    # Configure Waybar settings
  };

  home.file.".config/hypr" = {
    source = ./modules/hypr;
    recursive = true;
  };

  home.packages = with pkgs; [
    hyprland
    waybar
    alacritty
    zsh
    ghostty
  ];
}

