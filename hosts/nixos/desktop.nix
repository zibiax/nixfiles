{ config, lib, pkgs, user, ... }:

{
  imports = [ ./hardware/desktop.nix ];

  networking.hostName = "martin-linux";

  # ---------------------------------------------------------------- boot
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  zramSwap.enable = true;

  console.keyMap = "sv-latin1";
  services.xserver.xkb.layout = "se";

  # ---------------------------------------------------------------- data drives
  # Separate disks, so these UUIDs survive reformatting the NVMe.
  # nofail: don't drop to emergency mode if a drive is missing.
  fileSystems."/home/${user}/media/Vault" = {
    device = "/dev/disk/by-uuid/3EF0AF82F0AF3F51";
    fsType = "ntfs-3g";
    options = [ "permissions" "nofail" "x-gvfs-show" "x-gvfs-name=Vault" ];
  };
  fileSystems."/home/${user}/media/Backup" = {
    device = "/dev/disk/by-uuid/1636de45-33d3-4856-9bc6-14e16d0eebe9";
    fsType = "ext4";
    options = [ "nofail" "x-gvfs-name=Backup" ];
  };
  fileSystems."/home/${user}/media/Big" = {
    device = "/dev/disk/by-uuid/10961E31961E17B4";
    fsType = "ntfs-3g";
    options = [ "permissions" "nofail" "x-gvfs-show" "x-gvfs-name=Big" ];
  };

  # ---------------------------------------------------------------- nvidia (RTX 2060, Turing)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true; # was nvidia-open on Arch
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true; # keeps VRAM across suspend
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ---------------------------------------------------------------- user
  users.users.${user} = {
    description = "Martin";
    # Samba guests need to traverse ~ to reach ~/media (NixOS defaults to 700).
    homeMode = "755";
    extraGroups = [ "docker" "vboxusers" "wireshark" "rfkill" "input" "dialout" ];
  };

  # ---------------------------------------------------------------- desktop
  # Hyprland is started from tty1 by ~/.config/zsh/.zprofile (same as on Arch).
  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };
  programs.dconf.enable = true; # gsettings in theming.sh
  security.polkit.enable = true;
  security.pam.services.hyprlock = { };
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-media-tags-plugin thunar-volman ];
  };

  # ---------------------------------------------------------------- audio / bluetooth / printing
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # ---------------------------------------------------------------- gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # ---------------------------------------------------------------- virtualisation
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.virtualbox.host.enable = true;
  virtualisation.waydroid.enable = true;

  # ---------------------------------------------------------------- servers
  services.openssh.enable = true;

  # Share ~/media. Set the samba password once with: sudo smbpasswd -a ${user}
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server min protocol" = "SMB3_00";
        workgroup = "WORKGROUP";
        security = "user";
      };
      ${user} = {
        comment = "Martin-server";
        path = "/home/${user}/media";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0775";
        "directory mask" = "0775";
        public = "yes";
        writeable = "yes";
      };
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # MongoDB builds from source in nixpkgs (hours); run it in docker instead:
  #   docker run -d --name mongo --restart unless-stopped -p 27017:27017 -v mongo:/data/db mongo

  # Cloudflare tunnel (token-based on Arch). Put `TUNNEL_TOKEN=...` in
  # /etc/cloudflared/token.env (or an agenix secret) and uncomment:
  # systemd.services.cloudflared = {
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel run";
  #     EnvironmentFile = "/etc/cloudflared/token.env";
  #     DynamicUser = true;
  #     Restart = "on-failure";
  #   };
  # };

  # Ollama was installed but inactive on Arch. ollama-cuda is not in the
  # default binary cache, so enabling this compiles CUDA bits locally.
  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-cuda;
  # };

  # ---------------------------------------------------------------- misc programs
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true; # v4l2loopback
  };
  # Run unpatched binaries (mason LSPs, AppImages, downloaded tools).
  programs.nix-ld.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  services.flatpak.enable = true; # Bottles was a flatpak on Arch
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    source-han-sans
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.go-mono
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
    font-awesome
    liberation_ttf
    dejavu_fonts
    ubuntu-classic
    open-sans
    cantarell-fonts
  ];

  environment.systemPackages = with pkgs; [
    curl
    git
    wget
    ntfs3g
    exfatprogs
    pciutils
    usbutils
    lshw
    smartmontools
    efibootmgr
    socat
  ];

  system.stateVersion = lib.mkForce "26.05";
}
