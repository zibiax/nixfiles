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
| `modules/<app>/` | Raw dotfiles (hypr, waybar, nvim, rofi, tmux, ghostty, …) |
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
upgrade   # nix flake update + rebuild (replaces paru -Syu)
```

## Moving the desktop from EndeavourOS to NixOS

### 1. Back up before formatting the NVMe

`/home` lives on the NVMe, so everything in `~` that isn't on one of the data
drives (`~/media/{Vault,Backup,Big}`) is wiped. Those drives are mounted by
UUID in `hosts/nixos/desktop.nix` and come back automatically.

`~` is ~520 GB but most of it can be re-downloaded (Steam 123 GB, `~/Games`
84 GB, `~/.config/rpcs3` 35 GB, `~/.conda` 40 GB, lutris 12 GB, baloo index).
Must keep:

- [ ] `~/.ssh`, `~/.local/share/gnupg`, `~/.ssh/allowed_signers`
- [ ] Projects and documents: `~/Dev`, `~/Documents`, `~/Desktop`, `~/Ebooks*`, other repos in `~` (check for unpushed work)
- [ ] Anything worth keeping in `~/Downloads` (81 GB)
- [ ] App state you care about: `~/.config/google-chrome`, `~/.mozilla`, `~/.thunderbird`, `~/.config/Signal`, `~/.config/vesktop`, `~/.local/share/PrismLauncher`, emulator saves (rpcs3/pcsx2/ppsspp)
- [ ] `~/searxng/.env` (Caddy auth hash + hostname) and `~/searxng/searxng/settings.yml` secret key
- [ ] Jellyfin data: `/opt/jellyfin/docker/config`
- [ ] MariaDB: `sudo mariadb-dump --all-databases > all.sql`
- [ ] MongoDB: `mongodump` (MongoDB moves to docker, see `hosts/nixos/desktop.nix`)
- [ ] Docker volumes you need (`docker volume ls` — searxng, caddy, valkey)
- [ ] Cloudflare tunnel token (`systemctl cat cloudflared`)
- [ ] Commit/push this repo, `~/bin` (zibiax/bin), nvim (zibiax/nvim-config) and waybar (zibiax/waybar-config)

### 2. Install

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

### 3. After first boot

- Restore the backup into `~`.
- `sudo smbpasswd -a martin` (samba share of `~/media`)
- Restore MariaDB with `sudo mariadb < all.sql`.
- Docker stacks run from `~/nixfiles/docker/<stack>`: copy `.env` back into
  `docker/searxng/` and the jellyfin `config/` into `docker/jellyfin/` (both
  gitignored), then `docker compose up -d`.
- Open nvim and run `:PackerSync` (packer itself is cloned automatically).
  Mason-installed LSPs work through `programs.nix-ld`.

### What changed compared to Arch

- zgenom → zsh plugins from nixpkgs (fzf-tab, fzf-history-search, fast-syntax-highlighting, autosuggestions, history-substring-search). Aliases/env live in `home/modules/common.nix`.
- `exa` → `eza`; paru/pacman aliases → `rebuild`/`upgrade`/`updates`.
- conda dropped — use `nix shell`, devshells or direnv (`programs.direnv` is on).
- Polkit agent runs as a systemd user service (`hyprpolkitagent`) instead of `/usr/lib/...` exec lines.
- Waybar's `custom/pacman` now shows how old the nixpkgs lock is.
- Plex removed (server, 8443 proxy, client and `plexcron.sh`).
- Not ported (no nixpkgs package): MATLAB, Etcher, Popcorn Time, JDownloader, t3code, CUDA toolkit (use a devshell).
- Commented out in `hosts/nixos/desktop.nix`, enable when needed: cloudflared, ollama (CUDA).

## CachyOS kernel

The desktop runs `linuxPackages-cachyos-latest-lto-x86_64-v3` from
[nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel).
`.github/workflows/kernel.yml` builds it, together with the rest of the desktop
system (nvidia and virtualbox modules are built against the kernel), and pushes
the results to the `zibiax` Cachix cache. It runs on pushes that touch the
desktop config, by hand, and every Monday. Monday runs and manual runs with
"update" ticked bump the kernel first and commit `flake.lock` after a build
succeeds.

One-time setup:

1. Create a public cache on [cachix.org](https://app.cachix.org) (named
   `zibiax`, or set the repo variable `CACHIX_CACHE` and update `desktop.nix`).
2. Add an auth token for it as the repo secret `CACHIX_AUTH_TOKEN`.
3. Put the cache's public key into `nix.settings.extra-trusted-public-keys` in
   `hosts/nixos/desktop.nix`.

Updating: wait for the workflow to go green, then `upgrade` (pulls, then
rebuilds). Check `uname -r` after rebooting. If a rebuild starts compiling
`linux-...-cachyos`, the lock is ahead of the cache. Pull again or wait for CI.

## Secrets with agenix

SSH private keys (and other sensitive files) are deployed via [agenix](https://github.com/ryantm/agenix). To reuse an existing key without leaking it:

1. Generate an age identity per host. For NixOS machines you can reuse the host SSH key (`ssh-keyscan` is enough). For example:
   ```bash
   sudo cat /etc/ssh/ssh_host_ed25519_key.pub
   ```
   Copy the resulting public key into `secrets/age-recipients.nix` (see below).

2. Create `secrets/age-recipients.nix` describing which hosts may decrypt the secret:
   ```nix
   { "ssh/id_ed25519" = [
       # desktop host
       "age1...desktop-public-key"
       # laptop host
       "age1...laptop-public-key"
     ];
   }
   ```

3. Encrypt the key with agenix (install it via `nix shell .#agenix` or `nix run .#agenix -- --help`):
   ```bash
   agenix -e secrets/ssh/id_ed25519
   ```
   This reads `secrets/age-recipients.nix` and produces `secrets/ssh/id_ed25519.age`. The raw private key is never committed.

4. Ensure the original plain-text key is deleted (`shred` if on spinning disks) once the encryption is confirmed.

On rebuild, any NixOS host whose public key is listed will place the decrypted key at `~/.ssh/id_ed25519` with the correct permissions. macOS machines can use the same secret after you create an age identity at `~/.config/age/keys.txt` and add its public part to `secrets/age-recipients.nix`.
