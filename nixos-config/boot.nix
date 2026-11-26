{ lib, pkgs, ... }:

{
  boot = {
    # Lanzaboote replaces systemd-boot to sign boot artifacts.
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 3;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelPackages = pkgs.linuxPackages_cachyos;

    kernelModules = [ "tcp_bbr" ];

    consoleLogLevel = 3;

    kernelParams = [
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
      "amd_pstate=active"
      "preempt=full"
      "transparent_hugepage=madvise"
    ];

    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 150;
      "vm.page-cluster" = 1;
      "kernel.nmi_watchdog" = 0;
      "net.core.netdev_max_backlog" = 4096;
      "vm.vfs_cache_pressure" = 50;
    };
  };
}
