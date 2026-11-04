# Standalone Home-Manager auf Ubuntu (WSL) mit Nix Package Manager.
# Kein NixOS: nur Home-Manager-Optionen, keine system-/services-Ebene.
{ pkgs, ... }:

{
  imports = [
    ../../modules/common/home-common.nix
  ];

  home.username = "sebi";
  home.homeDirectory = "/home/sebi";
  home.stateVersion = "25.05";

  # Non-NixOS-Integration: XDG_DATA_DIRS, .desktop-Dateien, LOCALE_ARCHIVE
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  # Kundenkontext: kein Bitwarden-Zugriff
  my.rbw.enable = false;

  my.nvim.copilot.enable = true;
  my.graft.enable = true;

  # Rancher Desktop (Windows, nicht deinstallierbar) liegt via WSL-Interop im PATH;
  # sein docker-credential-secretservice wird sonst vom Docker-CLI automatisch genutzt
  # und scheitert an fehlendem libsecret.
  programs.zsh.initContent = ''
    path=(''${path:#*/Rancher Desktop/*})
  '';

  # Firmen-Proxy-CA (via update-ca-certificates im System-Bundle) auch für Tools
  # mit eigenem CA-Store: Node (copilot, npx) und Rust/OpenSSL.
  home.sessionVariables = {
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };

  my.tmuxSessionizer.paths = [
    "~/git"
    "~/git/exf"
  ];

  home.packages = with pkgs; [
    git
    openssh
    gh
    # dockerd läuft über manuelle /etc/systemd/system/docker.service
    # (ExecStart=/home/sebi/.nix-profile/bin/dockerd --group docker)
    docker
    docker-compose
  ];
}
