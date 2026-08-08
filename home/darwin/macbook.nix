{ pkgs, ... }:

{
  programs.alacritty.enable = true;

  home.packages = with pkgs; [
    jq
    wget
    aerospace
    helium
    ghostty
    awk

  ];

  home.file."Library/Application Support/ghostty/config" = {
    source = ../../modules/ghostty/config;
  };
}
