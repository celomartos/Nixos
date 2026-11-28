{
  pkgs,
  pkgs-stable,
  ...
}:

{
  # ============================================================================
  # USER PACKAGES
  # ============================================================================

  home.packages =

    (with pkgs; [

      # ==========================================================================
      # UNSTABLE
      # ==========================================================================

      # --------------------------------------------------------------------------
      # Terminal / CLI
      # --------------------------------------------------------------------------

      bat
      fastfetch
      btop
      curl
      wget
      jq
      gawk
      tree
      file
      dig

      # System information and diagnostics.
      lm_sensors
      pciutils
      psmisc

      # --------------------------------------------------------------------------
      # Development
      # --------------------------------------------------------------------------

      # AI / Coding tools.
      codex
      antigravity-cli

      # Programming tools.
      git
      lazygit
      gdb
      cmake
      gnumake
      clang
      pnpm
      electron

      # Code navigation and search.
      fd
      ripgrep
      fzf
      luaPackages.tree-sitter-cli

      # Android development.
      android-tools

      # Python environment.
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

      # --------------------------------------------------------------------------
      # Productivity
      # --------------------------------------------------------------------------

      obsidian

      # --------------------------------------------------------------------------
      # Desktop / Hyprland / Wayland
      # --------------------------------------------------------------------------

      hyprcursor
      hyprpolkitagent
      rofi
      waybar
      quickshell
      mako
      caelestia-shell

      # Clipboard and input.
      cliphist
      wl-clipboard
      ydotool
      wev

      # Wallpaper management.
      awww
      waypaper
      linux-wallpaperengine

      # Hyprland utilities.
      hyprpicker

      # --------------------------------------------------------------------------
      # Screenshot / Screen capture
      # --------------------------------------------------------------------------

      hyprshot
      grim
      slurp
      satty

      # --------------------------------------------------------------------------
      # GTK / Qt / Themes
      # --------------------------------------------------------------------------

      # GTK / Qt tools.
      nwg-look
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      kdePackages.kcolorscheme

      # GTK toolkits.
      gtk3
      gtk4

      # Qt style plugins.
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum

      # Icons.
      tela-icon-theme
      faba-mono-icons

      # --------------------------------------------------------------------------
      # File management / Storage
      # --------------------------------------------------------------------------

      # Btrfs tools.
      compsize
      snapper
      btrfs-assistant

      # Filesystem and removable media.
      ntfs3g
      woeusb
      gearlever

      # File format support.
      libgsf
      poppler
      webp-pixbuf-loader

      # Archive management.
      unzip
      unrar
      zip
      p7zip
      file-roller
      kdePackages.ark

      # --------------------------------------------------------------------------
      # Audio / Media
      # --------------------------------------------------------------------------

      easyeffects
      mpv
      cava
      ffmpeg
      playerctl

      # OBS Studio.
      obs-studio
      obs-studio-plugins.obs-pipewire-audio-capture
      obs-studio-plugins.obs-scene-as-transition
      obs-studio-plugins.obs-vkcapture

      # --------------------------------------------------------------------------
      # Browser / Internet
      # --------------------------------------------------------------------------

      brave-origin
      proton-vpn
      qbittorrent

      # --------------------------------------------------------------------------
      # Gaming / Compatibility
      # --------------------------------------------------------------------------

      prismlauncher
      mangohud
      wineWow64Packages.stable
      winetricks
      appimage-run
      hydralauncher
      protonup-qt

      # --------------------------------------------------------------------------
      # Graphics / Image editing
      # --------------------------------------------------------------------------

      gimp
      qview

      # --------------------------------------------------------------------------
      # Hardware / Performance diagnostics
      # --------------------------------------------------------------------------

      vulkan-tools
      mesa-demos
      geekbench
      stress-ng

    ])

    ++

      # ==========================================================================
      # STABLE
      # ==========================================================================

      (with pkgs-stable; [
        # Outros pacotes...
      ]);

}
