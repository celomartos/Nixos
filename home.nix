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
  home.file.".config/gtk-3.0".source =./home/gtk-3.0;
  home.file.".config/gtk-4.0".source = ./home/gtk-4.0;
  home.file.".config/nwg-look".source = ./home/nwg-look;

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
      font_family = "JetBrains Mono";
      font_size = 11;
      background_opacity = "0.7";
    };
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
    zed

    # --------------------------------------------------------------------------
    # Desktop / Wayland
    # --------------------------------------------------------------------------

    hyprcursor
    hyprpolkitagent
    waybar
    rofi
    cliphist
    mako


    # --------------------------------------------------------------------------
    # GTK / Qt
    # --------------------------------------------------------------------------

    nwg-look
    qt6Packages.qt6ct
    tela-icon-theme


    # --------------------------------------------------------------------------
    # File management / utilities
    # --------------------------------------------------------------------------

    qbittorrent
    qview


    # --------------------------------------------------------------------------
    # Audio / Media
    # --------------------------------------------------------------------------

    easyeffects
    mpv
    cava


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

    # --------------------------------------------------------------------------
    # Graphics / Recording
    # --------------------------------------------------------------------------

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
