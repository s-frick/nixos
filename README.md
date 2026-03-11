# NixOS Configuration (Flake)

Multi-host NixOS + Home-Manager setup.

## Hosts

| Host | Beschreibung |
|---|---|
| `silverback` | Desktop (AMD, MangoWC, Btrfs + Impermanence) |
| `fuji` | Laptop |
| `wsl` | Windows Subsystem for Linux |

## Rebuild

```bash
sudo nixos-rebuild switch --flake .#silverback
```

## Impermanence (silverback)

Root (`/`) und Home (`/home`) werden bei jedem Boot gewiped. Nur Pfade unter `/persist` überleben.

### Erstmalige Einrichtung (nach frischer Installation)

Leere Subvolumes erstellen, auf die bei jedem Boot zurückgesetzt wird:

```bash
sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvol=/ /dev/disk/by-uuid/dcce5d9e-4bc9-46a0-afb9-5af22a62e27d /mnt/btrfs-root
sudo btrfs subvolume create /mnt/btrfs-root/@root-blank
sudo btrfs subvolume create /mnt/btrfs-root/@home-blank
sudo umount /mnt/btrfs-root
```

### Neuen Pfad persistieren

Eintrag in `hosts/silverback/impermanence.nix` hinzufügen:
- System-Pfade unter `environment.persistence."/persist".directories` / `.files`
- User-Pfade unter `environment.persistence."/persist".users.sebi.directories` / `.files`

## Secrets (sops-nix)

Secrets werden mit [sops-nix](https://github.com/Mic92/sops-nix) verwaltet. Die verschlüsselte Datei `hosts/silverback/secrets.yaml` liegt im Repo. Entschlüsselt wird mit einem Age-Key, der aus dem SSH-Key abgeleitet ist.

### Erstmalige Einrichtung

```bash
# 1. Age-Key aus SSH-Key ableiten
mkdir -p ~/.config/sops/age
nix-shell -p ssh-to-age --run \
  "ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt"

# 2. Key nach /persist kopieren (System-Decrypt beim Boot)
sudo mkdir -p /persist/sops/age
sudo cp ~/.config/sops/age/keys.txt /persist/sops/age/keys.txt
sudo chmod 400 /persist/sops/age/keys.txt

# 3. Passwort-Hash erzeugen
mkpasswd -m sha-512

# 4. Secrets-File erstellen/editieren
nix-shell -p sops --run "sops hosts/silverback/secrets.yaml"
# Eintragen: sebi-password: "$6$..."

# 5. Rebuild
sudo nixos-rebuild switch --flake .#silverback
```

### Secret editieren

```bash
nix-shell -p sops --run "sops hosts/silverback/secrets.yaml"
```

### Passwort ändern

```bash
# Neuen Hash erzeugen
mkpasswd -m sha-512

# In secrets.yaml eintragen
nix-shell -p sops --run "sops hosts/silverback/secrets.yaml"

# Rebuild
sudo nixos-rebuild switch --flake .#silverback
```

`mutableUsers = false` bedeutet: `passwd` funktioniert nicht. Passwort-Änderungen nur über sops.

### Neuinstallation / neue Festplatte

Der Age-Key in `/persist` ist dann weg. So kommst du wieder rein:

1. **SSH-Key vorhanden** (z.B. aus Bitwarden-Backup):
   ```bash
   # Age-Key neu ableiten
   mkdir -p ~/.config/sops/age
   nix-shell -p ssh-to-age --run \
     "ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt"

   # Nach /persist kopieren und rebuild wie oben
   ```
   Die `secrets.yaml` kann mit dem gleichen Key entschlüsselt werden. Kein Datenverlust.

2. **SSH-Key verloren** (neuer Key):
   ```bash
   # Neuen Age-Pubkey ermitteln
   nix-shell -p ssh-to-age --run "cat ~/.ssh/id_ed25519.pub | ssh-to-age"

   # .sops.yaml mit neuem Pubkey aktualisieren
   # Dann secrets.yaml neu erstellen (Passwort-Hash neu erzeugen)
   nix-shell -p sops --run "sops hosts/silverback/secrets.yaml"
   ```
   Die alten Secrets können nicht mehr entschlüsselt werden. Passwort-Hash muss neu erzeugt werden.
