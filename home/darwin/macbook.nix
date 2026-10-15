{ pkgs, ... }:

{

  home.packages = with pkgs; [
    jq
    wget
    aerospace
    helium
    ghostty
    awk
    nvim
    sketchybar
  ];

  home.file."Library/Application Support/ghostty/config" = {
    source = ../../modules/ghostty/config;
  };
}
