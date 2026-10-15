{ config, pkgs, lib, user, ... }:

let
  # Configs are symlinked straight to the checkout (not copied to the store),
  # so edits in ~/.config/<app> land in the repo and apply without a rebuild.
  # Requires the repo to live at ~/nixfiles.
  repo = "${config.home.homeDirectory}/nixfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
  linkConfigs = names: lib.genAttrs names (name: { source = link "modules/${name}"; });
in
{
  home.username = user;
  home.stateVersion = "26.05";

  # ---------------------------------------------------------------- dotfiles
  xdg.configFile = linkConfigs [
    "hypr"
    "waybar"
    "nvim"
    "tmux"
    "rofi"
    "ghostty"
    "alacritty"
    "kitty"
    "foot"
    "wofi"
    "dunst"
    "mako"
    "btop"
    "mpd"
    "ncmpcpp"
    "lazygit"
    "mpv"
    "qt6ct"
    "ranger"
  ] // {
    "gtk-3.0/settings.ini".source = link "modules/gtk-3.0/settings.ini";
  };

  home.file = {
    ".local/scripts".source = link "modules/scripts/local";
    "bin".source = link "modules/scripts/bin";
    "Pictures/Wallpapers".source = link "wallpapers";
  };

  # packer.nvim isn't managed by itself; bootstrap it like on Arch.
  home.activation.packer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    packer="${config.xdg.dataHome}/nvim/site/pack/packer/opt/packer.nvim"
    if [ ! -d "$packer" ]; then
      run ${pkgs.git}/bin/git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer" || true
    fi
  '';

  # ---------------------------------------------------------------- shell
  programs.zsh = {
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ${repo}#desktop";
      upgrade = "nix flake update --flake ${repo} && sudo nixos-rebuild switch --flake ${repo}#desktop";
      updates = "nix flake update --flake ${repo} --output-lock-file /tmp/flake.lock.new && diff <(jq -S .nodes ${repo}/flake.lock) <(jq -S .nodes /tmp/flake.lock.new)";
      tmux-save = "~/bin/tmux-script.sh save";
      tmux-restore = "~/bin/tmux-script.sh restore";
      killtree = "~/bin/killtree.sh";
      hyprswitch = "~/bin/hyprswitch.sh";
      ollama-pull = "~/bin/ollama_pull.sh";
      tmux-session = "~/.local/scripts/tmux-sessions.sh";
    };
    initContent = ''
      ssh-add -l &>/dev/null || pass-cli ssh-agent load --vault-name "Personal" 2>/dev/null
    '';
    # Start Hyprland when logging in on tty1 (same as the Arch .zprofile).
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        if command -v start-hyprland >/dev/null; then exec start-hyprland; else exec Hyprland; fi
      fi
    '';
  };

  home.sessionVariables = {
    BROWSER = "google-chrome-stable";
    GTK_THEME = "Adwaita:dark";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    ELECTRON_FORCE_IS_NATIVE_DARK_MODE = "1";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    PROTON_PASS_KEY_PROVIDER = "fs";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    ANDROID_HOME = "${config.xdg.dataHome}/android";
  };

  # ---------------------------------------------------------------- theming
  home.pointerCursor = {
    enable = true;
    package = pkgs.simp1e-cursors;
    name = "Simp1e";
    size = 24;
  };

  # ---------------------------------------------------------------- user services
  services.hyprpolkitagent.enable = true;

  systemd.user.services.dunst = {
    Unit = {
      Description = "Dunst notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.dunst}/bin/dunst";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # mpd reads ~/.config/mpd/mpd.conf (linked from the repo)
  systemd.user.services.mpd = {
    Unit = {
      Description = "Music Player Daemon";
      After = [ "network.target" "sound.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # ---------------------------------------------------------------- packages
  home.packages = with pkgs; [
    # --- hyprland session
    waybar
    quickshell
    rofi
    rofimoji
    wofi
    dunst
    libnotify
    mako
    swaybg
    swayidle
    hypridle
    hyprlock
    hyprpicker
    grimblast
    grim
    slurp
    cliphist
    wl-clipboard
    pamixer
    playerctl
    libcanberra-gtk3 # canberra-gtk-play in volume/screenshot scripts
    sound-theme-freedesktop
    brightnessctl
    kanshi
    nwg-displays
    nwg-dock-hyprland
    wdisplays
    waypipe
    xwayland-satellite
    xrandr
    wlr-randr
    networkmanagerapplet
    pavucontrol
    qt6Packages.qt6ct
    lxappearance
    papirus-icon-theme
    tokyonight-gtk-theme
    adw-gtk3
    capitaine-cursors
    yad

    # --- terminals & editors
    ghostty
    alacritty
    kitty
    foot
    wezterm
    neovim
    zed-editor
    gedit
    meld
    diffuse

    # --- neovim tooling (packer builds/LSPs)
    gcc
    gnumake
    cmake
    nodejs
    tree-sitter
    lua-language-server
    clang-tools
    gopls
    rust-analyzer
    typescript-language-server
    jdt-language-server
    (python3.withPackages (ps: with ps; [
      pip
      python-lsp-server
      python-lsp-ruff
      pylsp-rope
      black
      pytest
      rich
      requests
      flask
      django
      pygame
      textual
      websockets
      boto3
      pandas
      jupyter
    ]))

    # --- cli
    tmux
    tmuxp
    lazygit
    lazydocker
    gh
    glab
    git-crypt
    ranger
    mc
    eza
    erdtree
    duf
    bottom
    glances
    nvtopPackages.nvidia
    s-tui
    fastfetch
    macchina
    onefetch
    cava
    cmatrix
    cowsay
    trash-cli
    pv
    bc
    w3m
    weechat
    yt-dlp
    ffmpeg
    imagemagick
    p7zip
    unrar
    innoextract
    sshfs
    sshpass
    rsync
    age
    agenix-cli
    whois
    traceroute
    dig
    iperf3
    ethtool
    nmap
    arp-scan
    pciutils
    lm_sensors
    android-tools
    mpc
    ncmpcpp
    mpd
    spotifyd
    claude-code

    # --- dev
    go
    zig
    rustup
    gdb
    gef
    strace
    ltrace
    meson
    ninja
    pkg-config
    gradle
    maven
    jdk17
    dotnet-sdk_8
    pypy3
    ruff
    mypy
    eslint
    dart-sass
    typst
    mermaid-cli
    mdbook
    mdbook-mermaid
    ansible
    ansible-lint
    iverilog
    gtkwave
    hexedit
    dbeaver-bin
    visualvm
    jetbrains.idea # unified IntelliJ; free tier replaces Community
    ghidra-bin
    qemu

    # --- security / ctf
    binwalk
    bettercap
    aircrack-ng
    hashcat
    hcxtools
    john
    ettercap
    fcrackzip
    ropgadget

    # --- browsers / communication
    firefox
    librewolf
    chromium
    google-chrome
    vivaldi
    thunderbird
    signal-desktop
    vesktop
    chatterino2
    zoom-us
    protonmail-bridge
    proton-vpn
    proton-pass
    proton-pass-cli # pass-cli (ssh-agent in zsh + hypr)
    bitwarden-desktop

    # --- media
    mpv
    vlc
    imv
    feh
    spotify
    pear-desktop # youtube-music
    cantata
    obs-studio
    handbrake
    delfin
    qbittorrent
    filezilla

    # --- graphics / office / cad
    gimp
    pinta
    kdePackages.kolourpaint
    blender
    freecad
    kicad
    openscad
    libreoffice
    calibre
    zathura
    sioyek
    kdePackages.okular

    # --- files
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.gwenview
    file-roller
    gnome-disk-utility
    kdiskmark
    rpi-imager

    # --- gaming
    lutris
    heroic
    prismlauncher
    protontricks
    protonup-qt
    wineWow64Packages.staging
    winetricks
    mangohud
    retroarch
    ppsspp
    pcsx2
    rpcs3
    shadps4
    chiaki-ng
    dosbox
    dwarf-fortress
    parsec-bin
    bottles
    looking-glass-client

    # --- misc
    cameractrls
    unityhub
    geekbench
    codex
    android-backup-extractor
    webcord
    tinymediamanager
  ];
}
