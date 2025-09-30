{ config, pkgs, lib, ... }:

{
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";

  programs.fzf.enable = true;
  programs.bat.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 7200;
    pinentryPackage = pkgs.pinentry-qt;
  };

  home.packages = with pkgs; [
    cliphist
    wl-clipboard
    xclip
  ];
}
