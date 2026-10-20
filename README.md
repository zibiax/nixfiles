# Nixfiles

The scope of this project is to create a portable config for NixOS, and MacOS. For my laptop, desktop, server, and mac.

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | Hosts: `desktop`, `laptop`, `headless-x86`, `raspberry-pi`, `macbook` |
| `hosts/nixos/desktop.nix` | System config for the main desktop (`martin-linux`: Ryzen 7 5700X, RTX 2060) |
| `hosts/nixos/hardware/desktop.nix` | Hardware config — **replace with the generated one when installing** |
| `home/modules/common.nix` | Home Manager config for every host: zsh, git, cli tools |
| `home/linux/desktop.nix` | Desktop apps, dotfile links, user services (dunst, mpd, polkit agent) |
| `modules/<app>/` | Raw dotfiles (hypr, quickshell, nvim, tmux, ghostty, …) |
| `modules/scripts/local` | Linked to `~/.local/scripts` |
| `modules/scripts/bin` | Linked to `~/bin` |
| `wallpapers/` | Linked to `~/Pictures/Wallpapers` |
| `docker/` | Compose stacks (searxng, jellyfin) |

On the desktop the dotfiles in `modules/` are linked with `mkOutOfStoreSymlink`,
so `~/.config/nvim` etc. point straight at this checkout. Edits apply instantly
and show up in `git status` — no rebuild needed. This only works if the repo
lives at **`~/nixfiles`**.

Day to day:

```bash
rebuild   # sudo nixos-rebuild switch --flake ~/nixfiles#desktop
upgrade   # git pull (CI's updated flake.lock) + rebuild (replaces paru -Syu)
```

## Moving the desktop from EndeavourOS to NixOS


### 1. Install

From the NixOS installer ISO:

```bash
# Partition the NVMe: 1 GB EFI (FAT32) + rest ext4, then
mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
nixos-generate-config --root /mnt

nix-shell -p git
git clone https://github.com/zibiax/nixfiles /mnt/home/martin/nixfiles
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/martin/nixfiles/hosts/nixos/hardware/desktop.nix
cd /mnt/home/martin/nixfiles && git add -A   # flakes only see tracked files

# The cache settings in desktop.nix only exist after install, so pass them here
# or the CachyOS kernel gets compiled locally (see "CachyOS kernel" below).
nixos-install --flake /mnt/home/martin/nixfiles#desktop \
  --option extra-substituters https://zibiax.cachix.org \
  --option extra-trusted-public-keys "zibiax.cachix.org-1:hv/erLbzkaytiLpCDbH5pEKSG1BopOwEiu4t2PrSRyY="
nixos-enter --root /mnt -c 'passwd martin && chown -R martin:users /home/martin'
reboot
```

Log in on tty1 and Hyprland starts (same as before, via `.zprofile`).

### 2. After first boot

- Restore the backup into `~`.
- `sudo smbpasswd -a martin` (samba share of `~/media`)
- Restore MariaDB with `sudo mariadb < all.sql`.
- Docker stacks run from `~/nixfiles/docker/<stack>`: copy `.env` back into
  `docker/searxng/` and the jellyfin `config/` into `docker/jellyfin/` (both
  gitignored), then `docker compose up -d`.
- Open nvim once while online: plugins come from nixpkgs, and vim.pack only
  fetches the few that aren't packaged (pinned in `modules/nvim/nvim-pack-lock.json`).
  Mason-installed LSPs work through `programs.nix-ld`.

### What changed compared to Arch

- zgenom → zsh plugins from nixpkgs (fzf-tab, fzf-history-search, fast-syntax-highlighting, autosuggestions, history-substring-search). Aliases/env live in `home/modules/common.nix`.
- `exa` → `eza`; paru/pacman aliases → `rebuild`/`upgrade`/`updates`.
- conda dropped — use `nix shell`, devshells or direnv (`programs.direnv` is on).
- Polkit agent runs as a systemd user service (`hyprpolkitagent`) instead of `/usr/lib/...` exec lines.

## CachyOS kernel

The desktop runs `linuxPackages-cachyos-latest-lto-x86_64-v3` from
[nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel).
`.github/workflows/kernel.yml` builds it, together with the rest of the desktop
system (nvidia and virtualbox modules are built against the kernel), and pushes
the results to the `zibiax` Cachix cache. It runs on pushes that touch the
desktop config, by hand, and every Monday. Monday runs and manual runs with
"update" ticked run `nix flake update` first, and `flake.lock` is committed
only after the whole system has built. Don't update the lock locally, or the
desktop will compile whatever CI hasn't built yet.

