{ config, pkgs, lib, ... }:

{
  home.homeDirectory = lib.mkDefault "/Users/${config.home.username}";

  programs.bat.enable = true;
  programs.fzf.enable = true;

  home.packages = with pkgs; [
    coreutils
    gnugrep
    gnused
  ];
}
