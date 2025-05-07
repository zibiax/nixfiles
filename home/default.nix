{ config, pkgs, ... }:

{
  home.username = "lakrisal";
  home.homeDirectory = "/home/lakrisal"
  home.stateVersion = "23.11";

  programs.git.enable = true;
  programs.zsh.enable = true;

  # Have to add platform neutral programs
}

