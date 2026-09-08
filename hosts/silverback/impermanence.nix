{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Wipe root and home subvolumes on every boot by rolling back to blank snapshots.
  # Requires one-time setup - create blank snapshots:
  #
  #   sudo mkdir -p /mnt/btrfs-root
  #   sudo mount -o subvol=/ /dev/disk/by-uuid/dcce5d9e-4bc9-46a0-afb9-5af22a62e27d /mnt/btrfs-root
  #   sudo btrfs subvolume create /mnt/btrfs-root/@root-blank
  #   sudo btrfs subvolume create /mnt/btrfs-root/@home-blank
  #   sudo umount /mnt/btrfs-root
  boot.initrd.systemd.services.rollback-root-home = {
    description = "Rollback @root and @home btrfs subvolumes to blank snapshots";
    after = [ "dev-disk-by\\x2duuid-dcce5d9e\\x2d4bc9\\x2d46a0\\x2dafb9\\x2d5af22a62e27d.device" ];
    requires = [ "dev-disk-by\\x2duuid-dcce5d9e\\x2d4bc9\\x2d46a0\\x2dafb9\\x2d5af22a62e27d.device" ];
    before = [ "sysroot.mount" ];
    requiredBy = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    # Without this the unit goes inactive after finishing and gets started a
    # second time when initrd-parse-etc triggers a daemon-reload and the
    # sysroot.mount Requires= is re-evaluated. That second run deleted @root
    # while it was mounted as /sysroot.
    serviceConfig.RemainAfterExit = true;
    script = ''
      set -euo pipefail
      if mountpoint -q /sysroot; then
        echo "rollback: /sysroot already mounted, refusing to run again" >&2
        exit 1
      fi
      dev=/dev/disk/by-uuid/dcce5d9e-4bc9-46a0-afb9-5af22a62e27d
      top=/btrfs-top
      mkdir -p "$top"
      mount -o subvol=/ "$dev" "$top"
      trap 'umount -R "$top" || true' EXIT

      rollback() {
        local sub="$1" blank="$2"
        # -R: delete nested subvolumes too. systemd-tmpfiles q/Q rules
        # (tmp, var/tmp, var/lib/machines, var/lib/portables) recreate
        # them on every boot because / is a btrfs subvolume.
        if [ -e "$top/$sub" ]; then
          btrfs subvolume delete -R "$top/$sub"
        fi
        if [ -e "$top/$sub" ]; then
          echo "rollback: $sub still exists after delete, refusing to snapshot into it" >&2
          exit 1
        fi
        btrfs subvolume snapshot "$top/$blank" "$top/$sub"
      }

      rollback @root @root-blank
      rollback @home @home-blank

      # Persist machine-id into fresh root before systemd starts
      if [ -f "$top/@persist/etc/machine-id" ]; then
        mkdir -p "$top/@root/etc"
        cp "$top/@persist/etc/machine-id" "$top/@root/etc/machine-id"
      fi
    '';
  };

  # Drop into an emergency shell with journal on any stage-1 failure
  # instead of hanging without a way to inspect the initrd.
  boot.initrd.systemd.emergencyAccess = true;

  # ── System-level persistence ──────────────────────────────────────────
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/coredump"
      "/var/lib/containers" # Podman
    ];

    files = [
    ];

    # ── User-level persistence (sebi) ─────────────────────────────────
    users.sebi = {
      directories = [
        # ── Git repos ──
        "git"

        # ── Credentials & secrets ──
        ".ssh"
        ".config/rbw" # Bitwarden CLI config
        ".local/share/rbw" # Bitwarden CLI vault data
        ".config/sops"
        ".config/nix"

        # ── Shell ──
        # .zsh_history → see files below

        # ── Development ──
        ".local/share/nvim" # Neovim state (undo, shada, etc.)
        ".local/state/nvim" # Neovim session state

        # ── Desktop / Apps ──
        ".config/BraveSoftware" # Brave browser profile
        ".config/DankMaterialShell" # DMS config
        ".local/state/DankMaterialShell" # DMS state
        ".config/lazygit" # Lazygit config
        ".local/state/lazygit" # Lazygit state
        ".config/obs-studio" # OBS profiles (created on first use)
        ".local/share/color-schemes" # Matugen color schemes
        ".config/GIMP" # GIMP settings
        ".local/share/gegl-0.4" # GIMP/GEGL data
        ".local/state/wireplumber" # Audio routing state
        ".config/pulse" # PulseAudio cookies

        # ── Theming (DMS/Matugen generated) ──
        ".config/dconf" # dconf DB (GTK theme settings)
        ".config/gtk-3.0" # dank-colors.css, gtk.css symlink
        ".config/gtk-4.0" # dank-colors.css
        ".config/foot" # dank-colors.ini
        ".config/kitty" # dank-theme.conf, dank-tabs.conf
        ".config/mango/dms" # DMS-Mango integration files

        # ── Claude ──
        ".claude"

        # ── Nix ──
        ".local/state/nix" # Nix profiles
        ".local/state/home-manager" # HM generations

        # ── PKI / certs ──
        ".pki"
      ];

      files = [
        ".zsh_history"
        ".bash_history"
        ".gitconfig"
        ".claude.json"
      ];
    };
  };
}
