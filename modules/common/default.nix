{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./nixos.nix
    ./home.nix
    ../windowManager/mango
  ];


  # Pullt nachts main von GitHub (flake-Attr setzt mkHost in flake.nix).
  # Lokale, ungepushte Änderungen werden dabei überschrieben.
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

  # Nach jedem autoUpgrade-Lauf: Bericht nach /var/lib/nixos-upgrade-report schreiben
  # (Fehler: Journal des Laufs, Erfolg: nvd-Diff) und als Notification zeigen, die
  # weggeklickt werden muss. Läuft keine Session, holt der User-Service sie beim Login nach.
  systemd.services.nixos-upgrade = {
    onFailure = [ "nixos-upgrade-notify@failure.service" ];
    onSuccess = [ "nixos-upgrade-notify@success.service" ];
  };
  systemd.services."nixos-upgrade-notify@" = {
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "nixos-upgrade-report";
    };
    path = [ pkgs.nvd ];
    scriptArgs = "%i";
    script = ''
      s=/var/lib/nixos-upgrade-report
      id=$(systemctl show -p InvocationID --value nixos-upgrade.service)
      if [ "$1" = failure ]; then
        journalctl _SYSTEMD_INVOCATION_ID="$id" -o cat --no-pager > $s/report.txt
        title="NixOS-Upgrade fehlgeschlagen"; body="$(grep -m1 '^error:' $s/report.txt || echo 'siehe Log')"; urg=critical
      else
        new=$(readlink -f /run/current-system)
        old=$(cat $s/system 2>/dev/null || true)
        if [ -z "$old" ] || [ "$old" = "$new" ]; then
          echo "Keine Änderung: $new" > $s/report.txt
          body="Keine Änderung"
        else
          nvd --color never diff "$old" "$new" > $s/report.txt 2>&1 || echo "nvd diff fehlgeschlagen ($old -> $new)" >> $s/report.txt
          body="$(grep -c '^\[' $s/report.txt || true) Pakete geändert"
        fi
        echo "$new" > $s/system
        title="NixOS-Upgrade erfolgreich"; urg=normal
      fi
      printf '%s\n%s\n%s\n%s\n' "$id" "$urg" "$title" "$body" > $s/status.tmp
      mv $s/status.tmp $s/status
      systemctl --machine=sebi@.host --user start --no-block nixos-upgrade-show.service || true
    '';
  };
  # Zeigt den letzten Bericht, bis er einmal weggeklickt wurde (auch beim Login).
  systemd.user.services.nixos-upgrade-show = {
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" "dms.service" ];
    path = [ pkgs.libnotify pkgs.xdg-utils ];
    serviceConfig = {
      Type = "oneshot";
      # DMS ist beim Login evtl. noch nicht bereit -> notify-send scheitert -> Retry
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      s=/var/lib/nixos-upgrade-report
      [ -r $s/status ] || exit 0
      { read -r id; read -r urg; read -r title; read -r body; } < $s/status
      seen="''${XDG_STATE_HOME:-$HOME/.local/state}/nixos-upgrade-seen"
      [ "$(cat "$seen" 2>/dev/null || true)" = "$id" ] && exit 0
      action=$(notify-send -u "$urg" -t 0 -a nixos-upgrade --action=report="Bericht öffnen" --wait "$title" "$body")
      mkdir -p "$(dirname "$seen")"
      echo "$id" > "$seen"
      if [ "$action" = report ]; then xdg-open $s/report.txt; fi
    '';
  };

  system.stateVersion = "25.05";
}
