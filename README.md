# Nixfiles

The scope of this project is to create a portable config for both NixOS and macOS. For my linux-laptop, desktop, server and mac-laptop.

I want to port over my neovim config, tmux config etc.

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
