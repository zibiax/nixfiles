{ config, pkgs, ... }:

{
  home.stateVersion = "23.11";
  programs.zsh.enable = true;
  programs.alacritty.enable = true;
  programs.git.enable = true;
  home.packages = with pkgs; [
    neovim
    tmux
    htop
    # Add other packages as needed
  ];
  home.file.".config/hypr" = {
    source = ../modules/hypr;
    recursive = true;
  };
}
