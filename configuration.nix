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

{ config, pkgs, cachyos-kernel, ... }:

{
  # ============================================================================
  # IMPORTS
  # ============================================================================

  imports = [
    /etc/nixos/hardware-configuration.nix
  ];


  # ============================================================================
  # NIXPKGS / KERNEL
  # ============================================================================

  nixpkgs.overlays = [
    cachyos-kernel.overlays.pinned
  ];

  boot.kernelPackages =
    cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest;

  boot.kernelParams = [
    "amd_pstate=active"
];

 boot.kernel.sysctl = {
  "vm.swappiness" = 100;
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
  # BOOT
  # ============================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # ============================================================================
  # NIX
  # ============================================================================

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org/"
      "https://attic.xuyh0120.win/lantian"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];

    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
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

  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
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
    # Basic utilities
    vim
    wget
    lm_sensors
    pciutils
    psmisc

    # Development
    gcc
    gdb
    cmake
    gnumake

    # Desktop / file management
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    zip
    unzip
    gtk3
    gtk4
    tree
    file

    # Version control
    git

    # Networking
    nextdns

    # Audio
    ffmpeg

    # Gaming
    protonup-qt
    mangohud

    # Graphics / Vulkan
    vulkan-tools
    mesa-demos
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
  # SSH
  # ============================================================================

  services.openssh = {
    enable = true;

    openFirewall = true;

    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;

      PermitRootLogin = "no";

      AllowUsers = [
        "celin"
      ];

      MaxAuthTries = 3;

      PerSourcePenalties =
        "crash:3600s authfail:3600s max:86400s";
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
