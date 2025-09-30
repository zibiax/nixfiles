{ pkgs, ... }:

{
  programs.alacritty.enable = true;

  home.packages = with pkgs; [
    jq
    wget
  ];

  home.file."Library/Application Support/ghostty/config" = {
    source = ../../modules/ghostty/config;
  };
}
