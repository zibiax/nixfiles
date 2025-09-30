{ config, pkgs, lib, ... }:

{
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  programs.git.delta.enable = true;

  home.packages = with pkgs; [
    bottom
    mosh
  ];
}
