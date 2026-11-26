{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  powerManagement.cpuFreqGovernor = "performance";

  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  # ============================================================================
  # SNAPSHOTS / BTRFS
  # ============================================================================

  services.snapper = {
    snapshotInterval = "weekly";
    persistentTimer = true;
    cleanupInterval = "1d";

    configs.home = {
      SUBVOLUME = "/home";
      FSTYPE = "btrfs";

      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;

      TIMELINE_LIMIT_HOURLY = 0;
      TIMELINE_LIMIT_DAILY = 0;
      TIMELINE_LIMIT_WEEKLY = 2;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 100;
    priority = 100;
  };

  services.fstrim.enable = true;
}
