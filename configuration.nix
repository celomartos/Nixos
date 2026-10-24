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

{
  config,
  pkgs,
  pkgs-stable,
  lib,
  waybar,
  ...
}:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot = {
    # Lanzaboote replaces the systemd-boot module to sign boot artifacts.
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 2;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelPackages = pkgs.linuxPackages_cachyos-bore;

    kernelModules = [ "tcp_bbr" ];

    consoleLogLevel = 3;
    initrd.verbose = false;

    kernelParams = [
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
      "amd_pstate=active"
      "preempt=full"
      "transparent_hugepage=madvise"
    ];

    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 130;
      "vm.page-cluster" = 1;
      "kernel.nmi_watchdog" = 0;
      "net.core.netdev_max_backlog" = 4096;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  nixpkgs.config.allowUnfree = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.backupFileExtension = "backup";

  home-manager.extraSpecialArgs = {
    inherit waybar;
  };

  home-manager.users.celin = import ./home.nix;

  # ============================================================================
  # NIX
  # ============================================================================

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 4d";
  };

  # ============================================================================
  # system identity
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

  # User service for keyboard and mouse automation.
  systemd.user.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold --socket-path=%t/.ydotool_socket";
      Restart = "on-failure";
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # SDDM mantido aqui como referência, mas desativado.
  # services.displayManager.sddm = {
  #   enable = true;
  #   wayland.enable = true;
  # };

  programs.regreet = {
    enable = true;
    theme = {
      name = "Graphite-Dark";
      package = pkgs.runCommand "graphite-dark-theme" { } ''
        mkdir -p $out/share/themes
        ln -s ${./home/Graphite-Dark} $out/share/themes/Graphite-Dark
      '';
    };
    iconTheme = {
      name = "Tela-circle-dark";
      package = pkgs.tela-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
      user = "greeter";
    };
  };

  # Portals used by desktop applications under Wayland.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # ============================================================================
  # FILE MANAGER
  # ============================================================================

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

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
  hardware.amdgpu.overdrive.enable = true;

  services.lact = {
    enable = true;
  };

  # ============================================================================
  # MEMORY / STORAGE
  # ============================================================================

  # Snapshots home.
  services.snapper = {
    snapshotInterval = "weekly";
    persistentTimer = true;
    cleanupInterval = "1d";

    configs = {
      home = {
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
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 100;
    priority = 100;
  };

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
      "com.stremio.Stremio"
      "com.usebottles.bottles"
    ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };

  # Flathub remote.
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Graphite theme for Flatpaks.
  systemd.user.services.flatpak-graphite-theme = {
    description = "Configurar tema Graphite nos Flatpaks";
    wantedBy = [ "default.target" ];

    path = with pkgs; [ coreutils flatpak ];
    script = ''
      themeDir="$HOME/.local/share/themes/Graphite-Dark"
      if [ -d "$themeDir" ] && [ ! -L "$themeDir" ]; then
        chmod -R u+w "$themeDir"
      fi
      rm -rf "$themeDir"
      mkdir -p "$HOME/.local/share/themes"
      cp -R ${./home/Graphite-Dark} "$themeDir"
      chmod -R u+w "$themeDir"

      flatpak override --user \
        --filesystem=$HOME/.themes:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-config/Kvantum:ro \
        --env=GTK_THEME=Graphite-Dark \
        --env=QT_STYLE_OVERRIDE=kvantum
    '';

    serviceConfig.Type = "oneshot";
  };

  # Bottles Libadwaita colors.
  # Preserve existing CSS.
  systemd.user.services.bottles-graphite-css =
    let
      bottlesGtkCss = pkgs.writeText "bottles-graphite-gtk.css" ''
        :root {
          --window-bg-color: #1B1B1B;
          --view-bg-color: #1B1B1B;
          --headerbar-bg-color: #1B1B1B;
          --sidebar-bg-color: #1B1B1B;
          --secondary-sidebar-bg-color: #1B1B1B;
          --card-bg-color: #1B1B1B;
          --dialog-bg-color: #1B1B1B;
          --popover-bg-color: #1B1B1B;
          --overview-bg-color: #1B1B1B;
          --thumbnail-bg-color: #1B1B1B;
        }
      '';
    in
    {
      description = "Aplicar cores Graphite ao Bottles";
      wantedBy = [ "default.target" ];

      path = [ pkgs.coreutils ];
      script = ''
        bottlesGtkCssTarget="$HOME/.var/app/com.usebottles.bottles/config/gtk-4.0/gtk.css"
        if [ ! -e "$bottlesGtkCssTarget" ]; then
          install -D -m 644 ${bottlesGtkCss} "$bottlesGtkCssTarget"
        fi
      '';

      serviceConfig.Type = "oneshot";
    };

  # ============================================================================
  # SYSTEM LOGGING
  # ============================================================================

  services.journald.settings.Journal = {
    SystemMaxUse = "500M";
    RuntimeMaxUse = "100M";
  };

  # ============================================================================
  # USER
  # ============================================================================

  users.users.celin = {
    isNormalUser = true;

    description = "celin";

    extraGroups = [
      "networkmanager"
      "wheel"
      "gamemode"
      "input"
      "libvirtd"
    ];
  };

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  # ============================================================================
  # FONTS
  # ============================================================================

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    texlivePackages.opensans
    noto-fonts
    texlivePackages.droid
    texlivePackages.roboto
  ];

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Network and security tools.
    nextdns
    sbctl

    # System diagnostics.
    geekbench
    stress-ng

    # Archive tools and file manager.
    p7zip
    unzip
    zip
    unrar
    file-roller

    # Screenshot tools.
    grim
    slurp

    # Windows and AppImage compatibility.
    wineWow64Packages.stable
    winetricks
    fuse3
    glib

    # Desktop application.
    chatgpt

    # Python environment for computer vision and utilities.
    (python3.withPackages (
      ps: with ps; [
        opencv4
        numpy
        pillow
        evdev
        pyinstaller
        pyqt5
      ]
    ))
  ];

  # Libraries for running dynamically linked programs outside Nix.
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      glib
      gobject-introspection
      nspr
      nss
      atk
      at-spi2-atk
      cups
      dbus
      cairo
      gtk3
      pango
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libgbm
      expat
      libxcb
      libxkbcommon
      systemd
      alsa-lib
      libglvnd
    ];
  };

  # ============================================================================
  # Session variables
  # ============================================================================

  environment.sessionVariables = {
    MESA_SHADER_CACHE_MAX_SIZE = "12G";
    GSK_RENDERER = "gl";
  };

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
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      ${pkgs.nextdns}/bin/nextdns activate
    '';
  };

  # ============================================================================
  # SCHEDULER
  # ============================================================================

  # systemd.services.scx-lavd = {
  #  description = "LAVD sched-ext scheduler";
  # wantedBy = [ "multi-user.target" ];
  #before = [ "multi-user.target" ];

  #serviceConfig = {
  # Type = "exec";
  #ExecStart = "${pkgs.scx.full}/bin/scx_lavd --performance";
  # Restart = "on-failure";
  # RestartSec = 2;
  #};
  #};

  # ============================================================================
  # VIRTUALIZATION
  # ============================================================================

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # ============================================================================
  # FIREWALL
  # ============================================================================

  networking.firewall = {
    enable = true;
  };

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  system.stateVersion = "26.05";
}
