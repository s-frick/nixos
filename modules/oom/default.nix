{ ... }:
{
  # Komprimierter Swap im RAM: verschafft Puffer bevor OOM eintritt
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Killt den größten Prozess bevor das System unbenutzbar wird.
  # Zuverlässiger als der Kernel-OOM-Killer, der oft erst nach
  # minutenlangem Thrashing eingreift.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

  boot.kernel.sysctl = {
    # Hohe swappiness ist mit zram sinnvoll: anonyme Pages billig
    # komprimieren statt Page-Cache (Code!) rauszuwerfen
    "vm.swappiness" = 180;
    # zram: Pages einzeln auslagern, kein Readahead nötig
    "vm.page-cluster" = 0;
    # Kernel reclaimt früher und gleichmäßiger statt in Panik-Bursts
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    # Magic SysRq: Alt+SysRq+F triggert OOM-Killer manuell als Notbremse
    "kernel.sysrq" = 1;
  };
}
