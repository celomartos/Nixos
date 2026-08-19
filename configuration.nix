# NixOS system configuration.
#
# System-level configuration:
# - Boot and kernel
# - Nix / flakes
# - Networking
# - Locale / keyboard
# - Hyprland / display manager
# - Audio
# - Hardware
# - Gaming
# - System services
# - User account
#
# User applications and application configuration are managed
# through Home Manager in ./home.nix.

{ config, pkgs,pkgs-stable, lanzaboote, lib, ... }:

  let
   pkgs-stable = import pkgs-stable {
    system = pkgs.system;
    config.allowUnfree = true;
    };
  in

{
  # ============================================================================
  # IMPORTS
  # ============================================================================

  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  # ============================================================================
  # BOOT / KERNEL
  # ============================================================================

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 3;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelPackages =
      pkgs.linuxPackages_latest;

    kernelParams = [
      "amd_pstate=active"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 100;
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.backupFileExtension = "backup";

  home-manager.users.celin = import ./home.nix;

  # ============================================================================
  # NIX
  # ============================================================================

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://nixpkgs.cachix.org"
      "https://cache.nixos.org/"
    ];

    trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ============================================================================
  # SYSTEM IDENTITY
  # ============================================================================

  networking.hostName = "nixos";

  # ============================================================================
  # NETWORKING
  # ============================================================================

  networking.networkmanager.enable = true;

  # ============================================================================
  # LOCALE / TIMEZONE
  # ============================================================================

  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "br-abnt2";

  # ============================================================================
  # GRAPHICS / HYPRLAND
  # ============================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # ============================================================================
  # AUDIO
  # ============================================================================

  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;

    # jack.enable = true;
  };

  # ============================================================================
  # HARDWARE
  # ============================================================================

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "performance";

  # ============================================================================
  # MEMORY / STORAGE
  # ============================================================================

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 100;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2 * 1024; # 2 GiB
    }
  ];

  services.fstrim.enable = true;

  # ============================================================================
  # GAMING
  # ============================================================================

  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  programs.gamemode.enable = true;

  # ============================================================================
  # FLATPAK
  # ============================================================================

  services.flatpak = {
    enable = true;

    packages = [
      "org.vinegarhq.Sober"
      "org.gtk.Gtk3theme.Breeze-Dark"
    ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };

  # ============================================================================
  # SYSTEM LOGGING
  # ============================================================================

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';

  # ============================================================================
  # USER
  # ============================================================================

  users.users.celin = {
    isNormalUser = true;

    description = "Celin";

    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  # ============================================================================
  # FONTS
  # ============================================================================

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [

    scx.full
    scx-loader
    nextdns
    sbctl

  ];

  # ============================================================================
  # NEXTDNS
  # ============================================================================

  services.nextdns = {
    enable = true;

    arguments = [
      "-config"
      "557a3a"
    ];
  };

  systemd.services.nextdns-activate = {
    after = [ "nextdns.service" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      ${pkgs.nextdns}/bin/nextdns activate
    '';
  };

  # ============================================================================
  # SCHEDULER
  # ============================================================================

  systemd.services.scx-lavd = {
    description = "LAVD sched-ext scheduler";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.scx.full}/bin/scx_lavd --performance";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # ============================================================================
  # FIREWALL
  # ============================================================================

  # networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ];

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  system.stateVersion = "26.05";
}
