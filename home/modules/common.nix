{ config, pkgs, lib, ... }:

{
  home.username = lib.mkDefault "lakrisal";
  home.stateVersion = lib.mkDefault "23.11";

  xdg.enable = true;

  programs.git = {
    enable = true;
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      export EDITOR=nvim
    '';
  };

  programs.starship.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.shellAliases = {
    ll = "ls -lh";
    gs = "git status";
  };

  home.packages = with pkgs; [
    fd
    ripgrep
    tree
  ];
}
