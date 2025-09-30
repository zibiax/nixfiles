{ config, lib, pkgs, user, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = lib.mkDefault "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  console.keyMap = lib.mkDefault "us";

  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    createHome = true;
    home = "/home/${user}";
    shell = pkgs.zsh;
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  networking.networkmanager.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    neovim
    wget
  ];

  services.openssh.enable = lib.mkDefault false;

  system.stateVersion = "24.05";
}
