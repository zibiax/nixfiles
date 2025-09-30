{ config, pkgs, ... }:

{
  networking.hostName = "nix-macbook";

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
    };
    dock.autohide = true;
    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
    };
  };

  security.pam.enableSudoTouchIdAuth = true;
  services.activationScripts.setDarkMode.text = ''
    /usr/bin/osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
  '';

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    brews = [ "mas" ];
    taps = [ "homebrew/cask" ];
    casks = [
      "rectangle"
      "raycast"
    ];
  };

  environment.systemPackages = with pkgs; [
    mas
  ];
}
