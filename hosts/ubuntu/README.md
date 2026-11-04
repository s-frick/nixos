# Runbook: Home-Manager auf WSL (Debian/Ubuntu) hinter Firmen-Proxy

Standalone Home-Manager (kein NixOS) für `homeConfigurations."sebi@ubuntu"`.
Der Firmen-Proxy bricht TLS auf und signiert mit eigener Root-CA → ohne die
CA scheitern apt, curl, Nix-Downloads und `fetchgit` in der Sandbox
(`self-signed certificate in certificate chain`).

## 1. systemd in WSL aktivieren

`/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

PowerShell: `wsl --shutdown`, dann WSL neu öffnen.

## 2. apt ohne TLS bootstrappen

```sh
sudo sed -i 's|https://|http://|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null
sudo apt-get update && sudo apt-get install -y ca-certificates curl
```

## 3. Firmen-Root-CAs aus Windows übernehmen

PowerShell (Windows, nicht WSL):

```powershell
Get-ChildItem Cert:\LocalMachine\Root | ForEach-Object {
  "-----BEGIN CERTIFICATE-----"
  [Convert]::ToBase64String($_.RawData, 'InsertLineBreaks')
  "-----END CERTIFICATE-----"
} | Set-Content -Encoding ascii "$env:USERPROFILE\corp-roots.crt"
```

WSL (`<win-user>` = Windows-Benutzerordner):

```sh
sudo cp /mnt/c/Users/<win-user>/corp-roots.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
curl -I https://github.com          # muss ohne SSL-Fehler durchlaufen
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null
```

## 4. Nix installieren (Determinate)

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --ssl-cert-file /etc/ssl/certs/ca-certificates.crt
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## 5. CA für Daemon und Build-Sandbox

```sh
# Daemon-Downloads (Substituter) + Datei wird in FOD-Sandbox gemountet
grep -q '^ssl-cert-file' /etc/nix/nix.conf || \
  sudo sh -c 'echo "ssl-cert-file = /etc/ssl/certs/ca-certificates.crt" >> /etc/nix/nix.conf'

# Fetcher in der Sandbox (fetchgit & Co.) erben NIX_SSL_CERT_FILE vom Daemon
sudo mkdir -p /etc/systemd/system/nix-daemon.service.d
printf '[Service]\nEnvironment=NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt\n' \
  | sudo tee /etc/systemd/system/nix-daemon.service.d/corp-ca.conf
sudo systemctl daemon-reload && sudo systemctl restart nix-daemon
```

Beides nötig. `NIX_GIT_SSL_CAINFO` hilft **nicht**: `nix-prefetch-git` setzt
daraus `GIT_SSL_CAINFO`, exportiert es aber nicht.

## 6. Home-Manager anwenden

```sh
nix run home-manager/master -- switch -b backup --flake 'github:s-frick/nixos#sebi@ubuntu'
```

Updates danach:

```sh
home-manager switch --refresh --flake 'github:s-frick/nixos#sebi@ubuntu'
```

`-b backup` benennt kollidierende Dotfiles nach `*.backup` um.

## 7. zsh als Login-Shell

```sh
echo ~/.nix-profile/bin/zsh | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/zsh
```

## 8. Docker (manuell, Home-Manager kann keine System-Services)

```sh
sudo groupadd -f docker && sudo usermod -aG docker sebi
printf '[Unit]\nDescription=Docker\nAfter=network-online.target\n\n[Service]\nExecStart=/home/sebi/.nix-profile/bin/dockerd --group docker\n\n[Install]\nWantedBy=multi-user.target\n' \
  | sudo tee /etc/systemd/system/docker.service
sudo systemctl daemon-reload && sudo systemctl enable --now docker
```

Neu einloggen (Gruppe), dann `docker run --rm hello-world`.

## 9. GitHub (GHE.com) + Copilot CLI

```sh
ssh-keygen -t ed25519 -C "sebi@VDI02"
gh auth login --hostname barmeniagothaer.ghe.com      # Device-Code, URL manuell öffnen
copilot login --host https://barmeniagothaer.ghe.com --device-code
```

Browser-OAuth-Flow (Redirect auf `127.0.0.1`) liefert HTTP 400 → Device-Code nutzen.

## Stolperfallen

| Symptom | Ursache | Fix (in `home.nix`) |
|---|---|---|
| `copilot login`: `error sending request for url` | Node/Rust nutzen eigenen CA-Store | `NODE_EXTRA_CA_CERTS`, `SSL_CERT_FILE` in `home.sessionVariables` |
| `docker run`: `docker-credential-secretservice … libsecret-1.so.0` | Rancher Desktop (Windows) via WSL-Interop im PATH; Docker-CLI nutzt den Helper automatisch | Rancher-Pfade in zsh aus `path` filtern |
| `git clone`: `cannot run ssh` | kein openssh | `openssh` in `home.packages` |

## Diagnose: was sieht die Sandbox?

```sh
nix build -L --impure --expr '
let pkgs = (builtins.getFlake "nixpkgs").legacyPackages.x86_64-linux; in
pkgs.runCommand "ca-test" {
  outputHash = pkgs.lib.fakeHash; outputHashMode = "recursive";
  impureEnvVars = [ "NIX_SSL_CERT_FILE" ];
} "echo VAR=[$NIX_SSL_CERT_FILE]; grep -c BEGIN /etc/ssl/certs/ca-certificates.crt; mkdir $out"'
```

Endet absichtlich mit `hash mismatch`. Erwartung: `VAR` gesetzt, Zertifikatsanzahl
gleich wie `grep -c BEGIN /etc/ssl/certs/ca-certificates.crt` auf dem Host.
