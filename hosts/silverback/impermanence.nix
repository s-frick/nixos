{ config, lib, inputs, pkgs, ... }:

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
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /mnt
    mount -o subvol=/ /dev/disk/by-uuid/dcce5d9e-4bc9-46a0-afb9-5af22a62e27d /mnt

    # Rollback @root
    btrfs subvolume delete /mnt/@root || true
    btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

    # Rollback @home
    btrfs subvolume delete /mnt/@home || true
    btrfs subvolume snapshot /mnt/@home-blank /mnt/@home

    # Persist machine-id into fresh root before systemd starts
    if [ -f /mnt/@persist/etc/machine-id ]; then
      mkdir -p /mnt/@root/etc
      cp /mnt/@persist/etc/machine-id /mnt/@root/etc/machine-id
    fi

    umount /mnt
  '';

  # ── System-level persistence ──────────────────────────────────────────
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/coredump"
      "/var/lib/containers"              # Podman
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
        ".config/rbw"                    # Bitwarden CLI config
        ".local/share/rbw"               # Bitwarden CLI vault data

        # ── Shell ──
        # .zsh_history → see files below

        # ── Development ──
        ".local/share/nvim"              # Neovim state (undo, shada, etc.)
        ".local/state/nvim"              # Neovim session state

        # ── Desktop / Apps ──
        ".config/BraveSoftware"          # Brave browser profile
        ".config/DankMaterialShell"      # DMS config
        ".local/state/DankMaterialShell" # DMS state
        ".config/lazygit"                # Lazygit config
        ".local/state/lazygit"           # Lazygit state
        ".config/obs-studio"             # OBS profiles (created on first use)
        ".local/share/color-schemes"     # Matugen color schemes
        ".config/GIMP"                   # GIMP settings
        ".local/share/gegl-0.4"          # GIMP/GEGL data
        ".local/state/wireplumber"       # Audio routing state
        ".config/pulse"                  # PulseAudio cookies

        # ── Theming (DMS/Matugen generated) ──
        ".config/dconf"                  # dconf DB (GTK theme settings)
        ".config/gtk-3.0"               # dank-colors.css, gtk.css symlink
        ".config/gtk-4.0"               # dank-colors.css
        ".config/foot"                   # dank-colors.ini
        ".config/kitty"                  # dank-theme.conf, dank-tabs.conf
        ".config/mango/dms"             # DMS-Mango integration files

        # ── Wakatime ──
        ".wakatime"

        # ── Claude ──
        ".claude"

        # ── Nix ──
        ".local/state/nix"               # Nix profiles
        ".local/state/home-manager"      # HM generations

        # ── PKI / certs ──
        ".pki"
      ];

      files = [
        ".zsh_history"
        ".bash_history"
        ".gitconfig"
        ".wakatime.cfg"
        ".claude.json"
      ];
    };
  };
}
