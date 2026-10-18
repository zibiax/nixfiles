{ config, pkgs, lib, ... }:

let
  zshPlugin = name: pkg: dir: file: {
    inherit name file;
    src = "${pkg}/${dir}";
  };
in
{
  home.username = lib.mkDefault "lakrisal";
  home.stateVersion = lib.mkDefault "23.11";

  xdg.enable = true;

  programs.git = {
    enable = true;
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDaGaVQO2NPpveAyT22N/2buyaREkMTf4TXS8VOdqy martin@evenbom.se";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "Martin";
        email = "martin@evenbom.se";
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      tag.gpgSign = true;
      alias.pr = "pull --rebase";
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
    };
  };

  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
  };

  # zsh: ported from ~/.config/zsh on the Arch install. zgenom is replaced by
  # nixpkgs plugins; options/keybinds/functions are sourced from modules/zsh.
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;

    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 10000;
      save = 10000;
      expireDuplicatesFirst = true;
      ignoreAllDups = true;
      ignoreDups = true;
      saveNoDups = true;
      # Match the Arch setup, where oh-my-zsh's lib turned these on.
      share = true;
      extended = true;
      ignoreSpace = true;
    };

    # Only oh-my-zsh's lib (no theme or plugins), as `zgenom ohmyzsh` loaded
    # it on Arch: directory aliases (..., -, 1-9), auto_pushd, key bindings,
    # completion menu, terminal title.
    oh-my-zsh.enable = true;

    plugins = [
      (zshPlugin "fzf-tab" pkgs.zsh-fzf-tab "share/fzf-tab" "fzf-tab.plugin.zsh")
      (zshPlugin "zsh-fzf-history-search" pkgs.zsh-fzf-history-search "share/zsh-fzf-history-search" "zsh-fzf-history-search.plugin.zsh")
      (zshPlugin "fast-syntax-highlighting" pkgs.zsh-fast-syntax-highlighting "share/zsh/plugins/fast-syntax-highlighting" "fast-syntax-highlighting.plugin.zsh")
    ];

    shellAliases = {
      rm = "rm -rIv";
      cp = "cp -rv";
      mv = "mv -v";
      mkdir = "mkdir -vp";
      grep = "rg";
      cat = "bat";
      c = "clear";
      q = "exit";

      la = "eza --icons -a --group-directories-first";
      ll = "eza --icons -lah --group-directories-first";
      ls = "eza --icons --group-directories-first";
      tree = "eza --icons --tree";

      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gb = "git branch";
      gc = "git commit --verbose";
      gcam = "git commit --all --message";
      gd = "git diff";
      gp = "git push";
      gs = "git status";

      rs = "curl --data-binary @- https://paste.rs | wl-copy";
      vim = "nvim";
      n = "nvim .";
    };

    initContent = ''
      source ${../../modules/zsh/options.zsh}
      source ${../../modules/zsh/keybinds.zsh}
      source ${../../modules/zsh/functions.zsh}
      source ${../../modules/zsh/keybinds-late.zsh}

      # Prompt
      setopt PROMPT_SUBST
      git_branch() {
        local branch_name
        branch_name=$(git branch 2>/dev/null | sed -n '/\* /s///p')
        if [ -n "$branch_name" ]; then
          echo -n "%F{green}[''${branch_name}]%f "
        fi
      }
      PROMPT='%F{blue}%n%: %~ $(git_branch)%F{reset}% '
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    SUDO_PROMPT = "[] Enter Password: ";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH = "0";
    ZSH_FZF_HISTORY_SEARCH_EVENT_NUMBERS = "0";
    ZSH_FZF_HISTORY_SEARCH_REMOVE_DUPLICATES = "1";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/scripts"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/bin"
    "${config.xdg.dataHome}/cargo/bin"
    "${config.home.homeDirectory}/go/bin"
  ];

  programs.fzf = {
    enable = true;
    # Ctrl-R stays with zsh-fzf-history-search, like on Arch
    enableZshIntegration = false;
  };
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.zoxide = {
    enable = true;
    options = [ "--cmd" "z" ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    zsh-completions
    fd
    ripgrep
    tree
    jq
    htop
    btop
    wget
    curl
    unzip
    zip
    tldr
  ];
}
