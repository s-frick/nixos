{ config, ... }:

# Taegliches restic-Backup auf die Hetzner Storage Box, ein Repo pro Host.
# Host setzt services.restic.backups.storagebox.paths und braucht sops
# (defaultSopsFile) mit diesen Keys:
#   restic/password  - restic Repo-Passwort
#   restic/ssh_key   - privater SSH-Key, eigener pro Host
#   restic/box_user  - Storage-Box-Benutzer (uXXXXXX)
#   restic/box_host  - uXXXXXX.your-storagebox.de
# Public Key pro Host einmalig auf die Box:
#   ssh-copy-id -f -p 23 -s -i key.pub <user>@<host>
let
  s = config.sops.secrets;
  p = config.sops.placeholder;
  t = config.sops.templates;
in
{
  sops.secrets = {
    "restic/password" = { };
    "restic/ssh_key" = { };
    "restic/box_user" = { };
    "restic/box_host" = { };
  };

  # Adresse nur in /run/secrets-rendered, nie im Repo oder Nix-Store
  sops.templates."restic-known-hosts".content = ''
    [${p."restic/box_host"}]:23 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs
  '';
  sops.templates."restic-ssh-config".content = ''
    Host storagebox
      HostName ${p."restic/box_host"}
      User ${p."restic/box_user"}
      Port 23
      IdentityFile ${s."restic/ssh_key".path}
      IdentitiesOnly yes
      UserKnownHostsFile ${t."restic-known-hosts".path}
      StrictHostKeyChecking yes
  '';

  services.restic.backups.storagebox = {
    initialize = true;
    repository = "sftp:storagebox:${config.networking.hostName}"; # relativ zum Box-Home
    passwordFile = s."restic/password".path;
    extraOptions = [
      "sftp.command='ssh -F ${t."restic-ssh-config".path} storagebox -s sftp'"
    ];

    exclude = [
      ".cache"
      "node_modules"
      "target"
      ".direnv"
      "result"
      "*/.local/share/Steam"
      "*/.local/share/Trash"
      "*/.config/BraveSoftware/*/*/Cache"
      "*/.config/BraveSoftware/*/*/Code Cache"
    ];
    extraBackupArgs = [ "--exclude-caches" ]; # respektiert CACHEDIR.TAG

    # Desktop ist nachts oft aus: Persistent holt den Lauf nach dem Booten nach
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];
  };
}
