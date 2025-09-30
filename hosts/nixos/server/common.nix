{ config, lib, pkgs, user, ... }:

{
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = lib.mkDefault true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = lib.mkDefault true;

  users.users.${user}.extraGroups = lib.mkForce [ "wheel" ];

  environment.systemPackages = with pkgs; [
    htop
    ncdu
    tmux
  ];

  services.fail2ban.enable = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
    dates = "daily";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=1G
    RuntimeMaxUse=256M
  '';

  networking.firewall = {
    enable = true;
    allowPing = false;
    trustedInterfaces = [ ];
  };
}
