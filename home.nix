{ config, pkgs, ... }:

{
  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  home.username = "celin";
  home.homeDirectory = "/home/celin";

  # Version of Home Manager whose stateful defaults should be preserved.
  home.stateVersion = "26.05";

  # ============================================================================
  # CONFIGURATION FILES
  # ============================================================================

  home.file.".config/hypr".source = ./home/hyprland;
  home.file.".config/waybar".source = ./home/waybar;
  home.file.".config/rofi".source = ./home/rofi;
  home.file.".config/mako".source = ./home/mako;
  home.file.".config/cava".source = ./home/cava;

  # ============================================================================
  # FISH
  # ============================================================================

  programs.fish = {
    enable = true;

    # Custom Fish prompt.
    functions = {
      fish_prompt = {
        body = ''
          set_color "#00D7FF"
          echo -n "in "(prompt_pwd)
          set_color normal
          echo -n " \$ "
        '';
      };
    };

    # Shell aliases.
    shellAliases = {
      nrs = "sudo nixos-rebuild switch";
    };

    # Commands executed when an interactive Fish shell starts.
    interactiveShellInit = ''
      set -g fish_greeting
      pfetch
    '';
  };

  programs.firefox.enable = true;

  # ============================================================================
  # KITTY
  # ============================================================================

  programs.kitty = {
    enable = true;

    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 11;
      background_opacity = "0.7";
    };
  };

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  # ============================================================================
  # FASTFETCH
  # ============================================================================

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
      "modules": [
        {
          "type": "custom",
          "format": " "
        },

        {
          "type": "custom",
          "format": "──────────────"
        },

        "os",
        "host",
        "kernel",
        "uptime",

        {
          "type": "custom",
          "format": " "
        },

        {
          "type": "custom",
          "format": "──────────────"
        },

        "packages",
        "shell",
        "display",
        "wm",
        "terminal",

        {
          "type": "custom",
          "format": " "
        },

        {
          "type": "custom",
          "format": "──────────────"
        },

        "cpu",
        "gpu",
        "memory",
        "swap",
        "disk",

        {
          "type": "custom",
          "format": " "
        }
      ]
    }
  '';

  # ============================================================================
  # MIMEAPPS
  # ============================================================================

  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "text/plain" = "dev.zed.Zed.desktop";
      "text/x-c" = "dev.zed.Zed.desktop";
      "text/x-c++" = "dev.zed.Zed.desktop";
      "text/x-python" = "dev.zed.Zed.desktop";
      "text/x-java" = "dev.zed.Zed.desktop";
      "text/x-shellscript" = "dev.zed.Zed.desktop";
      "text/x-makefile" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";
    };
  };

  xdg.desktopEntries.kitty = {
    name = "Kitty";
    genericName = "Terminal Emulator";
    exec = "kitty";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  # ============================================================================
  # CURSOR
  # ============================================================================

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  # ============================================================================
  # USER PACKAGES
  # ============================================================================

  home.packages = with pkgs; [

    # --------------------------------------------------------------------------
    # Terminal / CLI
    # --------------------------------------------------------------------------

    bat
    pfetch
    fastfetch
    btop
    curl
    wget
    lm_sensors
    pciutils
    psmisc
    playerctl
    wev

    # --------------------------------------------------------------------------
    # Development
    # --------------------------------------------------------------------------

    gcc
    gdb
    cmake
    gnumake
    zed-editor
    neovim
    git
    luaPackages.tree-sitter-cli


    # --------------------------------------------------------------------------
    # Desktop / Wayland
    # --------------------------------------------------------------------------

    hyprcursor
    hyprpolkitagent
    waybar
    rofi
    cliphist
    wl-clipboard
    mako
    hyprpicker

    # --------------------------------------------------------------------------
    # GTK / Qt
    # --------------------------------------------------------------------------

    nwg-look
    qt6Packages.qt6ct
    gtk3
    gtk4
    tela-icon-theme
    kdePackages.breeze
    kdePackages.breeze-gtk

    # --------------------------------------------------------------------------
    # File management / utilities
    # --------------------------------------------------------------------------

    qbittorrent
    qview
    thunar
    xfce4-settings
    tumbler
    libgsf
    poppler
    webp-pixbuf-loader
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    zip
    unzip
    tree
    file

    # --------------------------------------------------------------------------
    # Audio / Media
    # --------------------------------------------------------------------------

    easyeffects
    mpv
    cava
    ffmpeg

    # --------------------------------------------------------------------------
    # Browser / Internet
    # --------------------------------------------------------------------------

    qutebrowser
    proton-vpn

    # --------------------------------------------------------------------------
    # Gaming
    # --------------------------------------------------------------------------

    vesktop
    linux-wallpaperengine
    prismlauncher
    protonup-qt
    mangohud

    # --------------------------------------------------------------------------
    # Graphics / Vulkan
    # --------------------------------------------------------------------------

    vulkan-tools
    mesa-demos
    gimp
    hyprshot
    obs-studio

    # OBS plugins.
    obs-studio-plugins.obs-pipewire-audio-capture
    obs-studio-plugins.obs-move-transition
    obs-studio-plugins.obs-scene-as-transition
    obs-studio-plugins.obs-vkcapture
  ];
}
