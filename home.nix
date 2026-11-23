{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./home/nixvim/default.nix ];

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

  # home.file.".config/hypr/".source = ./home/hyprland;
  # home.file.".config/rofi".source = ./home/rofi;
  # home.file.".config/quickshell".source = ./home/quickshell;
  home.file.".config/waybar".source = ./home/waybar;
  home.file.".config/mako".source = ./home/mako;
  home.file.".config/Kvantum/Graphite".source = ./home/Graphite;
  #home.file.".config/Vencord".source = ./home/Vencord;

  # ============================================================================
  # FISH
  # ============================================================================

  programs.fish = {
    enable = true;

    # Custom Fish prompt and helper functions.
    functions = {
      fish_prompt = {
        body = ''
          set_color "#FFFFFF"

          if test "$PWD" = "$HOME"
            echo -n "in ~"
          else
            echo -n "in "(basename $PWD)
          end

          set_color normal
          echo -n " >_ "
        '';
      };

      extract = ''
        switch $argv[1]
          case '*.tar.gz' '*.tgz'
            tar -xzf $argv[1]
          case '*.tar.xz' '*.txz'
            tar -xJf $argv[1]
          case '*.tar.bz2' '*.tbz2'
            tar -xjf $argv[1]
          case '*.tar.zst' '*.tzst'
            tar --zstd -xf $argv[1]
          case '*.tar'
            tar -xf $argv[1]
          case '*.zip'
            unzip $argv[1]
          case '*.7z'
            7z x $argv[1]
          case '*.rar'
            unrar x $argv[1]
          case '*'
            echo "Formato não suportado: $argv[1]"
            return 1
        end
      '';

      nrs = ''
        cd ~/nixos
        sudo nixos-rebuild switch --flake . --impure; and \
        sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3; and \
        sudo nix-collect-garbage
      '';
    };

    # Commands executed when an interactive Fish shell starts.
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  # ============================================================================
  # KITTY
  # ============================================================================

  programs.kitty = {
    enable = true;

    settings = {
      font_family = "MonaspiceNe Nerd Font Mono";
      font_size = 12;
      background = "#111111";
      background_opacity = "0.7";
      background_blur = "0";
      remember_window_size = "no";

      # Abas
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_min_tabs = 2;

      # Aba selecionada
      active_tab_foreground = "#000000";
      active_tab_background = "#ffffff";
      active_tab_font_style = "bold";

      # Abas inativas
      inactive_tab_foreground = "#a1a1aa";
      inactive_tab_background = "#27272a";
      inactive_tab_font_style = "normal";

      # Fundo da barra
      tab_bar_background = "#18181b";
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

      "logo": {
        "type": "kitty",
        "height": 16,
        "source": "/home/celin/.config/fastfetch/fastfetch.png",
        "padding": {
          "right": 4
        }
      },

      "display": {
        "color": {
          "keys": "white",
          "output": "white"
        },
        "key": {
          "width": 13,
          "type": "both"
        },
        "brightColor": false
      },

      "modules": [

        {
          "type": "break"
        },

        {
          "type": "title",
          "format": "{user-name}@{host-name}"
        },

        {
          "type": "os",
          "key": "System  | ",
          "keyIcon": "",
          "format": "{name} {version}"
        },

        {
          "type": "kernel",
          "key": "Kernel  | ",
          "keyIcon": ""
        },

        {
          "type": "shell",
          "key": "Shell   | ",
          "keyIcon": ""
        },

        {
          "type": "packages",
          "key": "Pkgs    | ",
          "keyIcon": ""
        },

        {
          "type": "wm",
          "key": "WM      | ",
          "keyIcon": ""
        },

        {
          "type": "uptime",
          "key": "Uptime  | ",
          "keyIcon": ""
        },

        {
          "type": "custom",
          "format": "────────────────────────────"
        },

        {
          "type": "gpu",
          "key": "GPU     | ",
          "keyIcon": ""
        },

        {
          "type": "cpu",
          "key": "CPU     | ",
          "keyIcon": ""
        },

        {
          "type": "memory",
          "key": "Memory  | ",
          "keyIcon": ""
        },

        {
          "type": "swap",
          "key": "Swap    | ",
          "keyIcon": ""
        },

        {
          "type": "disk",
          "key": "Storage | ",
          "keyIcon": "",
          "folders": "/"
        }
      ]
    }
  '';

  # ============================================================================
  # MIMEAPPS
  # ============================================================================

  xdg.enable = true;

  xdg.desktopEntries = {
    "thunar" = {
      name = "Thunar";
      exec = "thunar %U";
      noDisplay = true;
    };

    "thunar-bulk-rename" = {
      name = "Thunar Bulk Rename";
      exec = "thunar --bulk-rename %F";
      noDisplay = true;
    };

    "thunar-settings" = {
      name = "Thunar Settings";
      exec = "thunar-settings";
      noDisplay = true;
    };

    "thunar-volman-settings" = {
      name = "Thunar Volume Manager";
      exec = "thunar-volman-settings";
      noDisplay = true;
    };

    "org.gnome.FileRoller" = {
      name = "File Roller";
      exec = "file-roller %U";
      noDisplay = true;
    };

    "org.gtk.PrintEditor4" = {
      name = "GTK4 Print Editor";
      exec = "gtk4-print-editor";
      noDisplay = true;
    };

    "org.gtk.Demo4" = {
      name = "GTK4 Demo";
      exec = "gtk4-demo";
      noDisplay = true;
    };

    "org.gtk.WidgetFactory4" = {
      name = "GTK4 Widget Factory";
      exec = "gtk4-widget-factory";
      noDisplay = true;
    };

    "org.gtk.gtk4.NodeEditor" = {
      name = "GTK4 Node Editor";
      exec = "gtk4-node-editor";
      noDisplay = true;
    };
  };

  # ============================================================================
  # GTK / ICON THEME
  # ============================================================================

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";

      package = pkgs.papirus-icon-theme.override {
        color = "black";
      };
    };
  };

  xdg.desktopEntries.neovim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "kitty nvim %F";
    terminal = false;
    noDisplay = true;
    type = "Application";
    categories = [
      "Utility"
      "TextEditor"
      "Development"
    ];

    mimeType = [
      "text/plain"
      "text/x-c"
      "text/x-c++"
      "text/x-python"
      "text/x-java"
      "text/x-shellscript"
      "text/x-makefile"
      "application/json"
      "application/xml"
    ];
  };

  xdg.desktopEntries.qview = {
    name = "qView";
    genericName = "Image Viewer";
    exec = "qview %F";
    terminal = false;
    noDisplay = true;
    type = "Application";
    categories = [
      "Graphics"
      "Viewer"
    ];

    mimeType = [
      # Formatos comuns
      "image/jpeg"
      "image/jpg"
      "image/png"
      "image/gif"
      "image/webp"
      "image/bmp"
      "image/tiff"
      "image/svg+xml"

      # Formatos modernos
      "image/avif"
      "image/avif-sequence"
      "image/heic"
      "image/heif"
      "image/apng"
      "image/jxl"

      # Formatos de edição
      "image/vnd.adobe.photoshop"
      "image/x-xcf"
      "image/openraster"
      "application/psd"
      "application/photoshop"
      "application/x-krita"

      # Formatos adicionais
      "image/icns"
      "image/x-icon"
      "image/x-tga"
      "image/x-pcx"
      "image/x-portable-bitmap"
      "image/x-portable-graymap"
      "image/x-portable-pixmap"
      "image/x-portable-anymap"
      "image/x-exr"
      "image/x-rgb"
      "image/x-sgi"
      "image/x-sgi-bw"
      "image/x-sgi-rgba"
      "image/x-sun-raster"
      "image/vnd.radiance"
      "image/vnd.wap.wbmp"
    ];
  };

  xdg.mimeApps.defaultApplications = {
    "image/jpeg" = "qview.desktop";
    "image/jpg" = "qview.desktop";
    "image/png" = "qview.desktop";
    "image/gif" = "qview.desktop";
    "image/webp" = "qview.desktop";
    "image/bmp" = "qview.desktop";
    "image/tiff" = "qview.desktop";
    "image/svg+xml" = "qview.desktop";
    "image/avif" = "qview.desktop";
    "image/avif-sequence" = "qview.desktop";
    "image/heic" = "qview.desktop";
    "image/heif" = "qview.desktop";
    "image/apng" = "qview.desktop";
    "image/jxl" = "qview.desktop";
    "image/vnd.adobe.photoshop" = "qview.desktop";
    "image/x-xcf" = "qview.desktop";
    "image/openraster" = "qview.desktop";
    "application/psd" = "qview.desktop";
    "application/photoshop" = "qview.desktop";
    "application/x-krita" = "qview.desktop";
    "image/icns" = "qview.desktop";
    "image/x-icon" = "qview.desktop";
    "image/x-tga" = "qview.desktop";
    "image/x-pcx" = "qview.desktop";
    "image/x-portable-bitmap" = "qview.desktop";
    "image/x-portable-graymap" = "qview.desktop";
    "image/x-portable-pixmap" = "qview.desktop";
    "image/x-portable-anymap" = "qview.desktop";
    "image/x-exr" = "qview.desktop";
    "image/x-rgb" = "qview.desktop";
    "image/x-sgi" = "qview.desktop";
    "image/x-sgi-bw" = "qview.desktop";
    "image/x-sgi-rgba" = "qview.desktop";
    "image/x-sun-raster" = "qview.desktop";
    "image/vnd.radiance" = "qview.desktop";
    "image/vnd.wap.wbmp" = "qview.desktop";
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];

      # Text editor.
      "text/plain" = [ "neovim.desktop" ];
      "text/x-c" = [ "neovim.desktop" ];
      "text/x-c++" = [ "neovim.desktop" ];
      "text/x-python" = [ "neovim.desktop" ];
      "text/x-java" = [ "neovim.desktop" ];
      "text/x-shellscript" = [ "neovim.desktop" ];
      "text/x-makefile" = [ "neovim.desktop" ];
      "application/json" = [ "neovim.desktop" ];
      "application/xml" = [ "neovim.desktop" ];

      # Compressed archives.
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
    };
  };

  xdg.desktopEntries.kitty = {
    name = "Kitty";
    genericName = "Terminal Emulator";
    exec = "kitty";
    noDisplay = true;
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  # ============================================================================
  # STREMIO
  # ============================================================================

  home.file.".local/share/applications/com.stremio.Stremio.desktop".text = ''
    [Desktop Entry]
    Name=Stremio
    Comment=Freedom To Stream
    Icon=com.stremio.Stremio
    Categories=Utility;AudioVideo;Video;Player;
    Type=Application
    Exec=flatpak run --branch=stable --arch=x86_64 --command=stremio com.stremio.Stremio --no-window-decorations
    Terminal=false
    StartupNotify=true
    DBusActivatable=false
    MimeType=x-scheme-handler/stremio;
  '';

  # ============================================================================
  # CURSOR
  # ============================================================================

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.graphite-cursors;
    name = "graphite-dark";
    size = 24;
  };

  # ============================================================================
  # CLIPHIST HISTORY CLEANUP
  # ============================================================================

  systemd.user.services.cliphist-clear = {
    Unit.Description = "Clear the cliphist history";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.cliphist}/bin/cliphist wipe";
    };
  };

  systemd.user.timers.cliphist-clear = {
    Unit.Description = "Clear cliphist every 1 hour";
    Timer = {
      OnBootSec = "60m";
      OnUnitActiveSec = "60m";
      Unit = "cliphist-clear.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # ============================================================================
  # USER PACKAGES
  # ============================================================================

  home.packages = with pkgs; [
    # --------------------------------------------------------------------------
    # Terminal / CLI
    # --------------------------------------------------------------------------

    bat
    fastfetch
    btop
    curl
    wget
    lm_sensors
    pciutils
    psmisc
    jq
    codex
    woeusb
    ntfs3g

    # --------------------------------------------------------------------------
    # Development
    # --------------------------------------------------------------------------

    android-tools
    gdb
    cmake
    gnumake
    git
    luaPackages.tree-sitter-cli
    lazygit
    fd
    ripgrep
    fzf
    clang
    pnpm
    electron
    obsidian

    # --------------------------------------------------------------------------
    # Desktop / Wayland
    # --------------------------------------------------------------------------

    hyprcursor
    hyprpolkitagent
    rofi
    cliphist
    wl-clipboard
    mako
    hyprpicker
    awww
    waypaper
    ydotool
    playerctl
    wev
    hyprshot
    slurp
    waybar
    quickshell
    linux-wallpaperengine
    satty
    gawk

    # --------------------------------------------------------------------------
    # GTK / Qt
    # --------------------------------------------------------------------------

    nwg-look
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    gtk3
    gtk4
    tela-icon-theme
    faba-mono-icons
    kdePackages.kcolorscheme
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum

    # --------------------------------------------------------------------------
    # File management / storage
    # --------------------------------------------------------------------------

    compsize
    snapper
    btrfs-assistant
    libgsf
    poppler
    webp-pixbuf-loader
    tree
    file
    gearlever

    # --------------------------------------------------------------------------
    # Audio / Media
    # --------------------------------------------------------------------------

    easyeffects
    mpv
    cava
    ffmpeg
    obs-studio

    # OBS plugins.
    obs-studio-plugins.obs-pipewire-audio-capture
    obs-studio-plugins.obs-scene-as-transition
    obs-studio-plugins.obs-vkcapture

    # --------------------------------------------------------------------------
    # Browser / Internet
    # --------------------------------------------------------------------------

    proton-vpn
    brave-origin
    qbittorrent

    # --------------------------------------------------------------------------
    # Gaming
    # --------------------------------------------------------------------------

    prismlauncher
    mangohud
    wine
    appimage-run
    hydralauncher
    protonup-qt

    # --------------------------------------------------------------------------
    # Graphics / Vulkan
    # --------------------------------------------------------------------------

    vulkan-tools
    mesa-demos
    gimp
    qview
    lact
  ];
}
