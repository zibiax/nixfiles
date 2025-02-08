{
  description = "Cross-platform System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, darwin, hyprland, ... }@inputs:
    let
      mkSystem = import ./lib/mksystem.nix;
    in
    {
      nixosConfigurations.desktop = mkSystem {
        inherit inputs;
        system = "x86_64-linux";
        hostname = "desktop";
        username = "your-username";
      };

      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";  # Use x86_64-darwin for Intel Macs
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/macbook
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.your-username = import ./home/shared.nix;
          }
        ];
      };
    };
}

# lib/mksystem.nix
{ inputs, system, hostname, username }:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../hosts/${hostname}
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = { pkgs, ... }: {
        imports = [
          ../home/default.nix
          ../home/hyprland.nix
          ../home/waybar.nix
        ];
      };
    }
  ];
}

# hosts/macbook/default.nix
{ config, pkgs, inputs, ... }:

{
  # Enable nix-darwin system defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];

  # Enable services
  services = {
    nix-daemon.enable = true;
    yabai = {
      enable = true;
      config = {
        layout = "bsp";
        window_gap = 10;
      };
    };
    skhd = {
      enable = true;
      skhdConfig = ''
        # Quick window management
        alt - h : yabai -m window --focus west
        alt - j : yabai -m window --focus south
        alt - k : yabai -m window --focus north
        alt - l : yabai -m window --focus east
      '';
    };
  };

  # System settings
  system.stateVersion = 4;
}

# home/shared.nix
{ config, pkgs, ... }:

{
  # Shared packages for both platforms
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    exa
    fzf
    jq
    neovim
    zoxide
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Martin Evenbom";
    userEmail = "martin.evenbom@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
      pull.rebase = true;
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "docker" "fzf" ];
    };
  };

  # Shared environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
  };
}

