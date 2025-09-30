{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks."*" = {
      forwardX11 = false;
      serverAliveInterval = 60;
    };
  };

  home.packages = with pkgs; [
    rsync
    sysstat
  ];
}
