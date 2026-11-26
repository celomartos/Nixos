{
  config,
  lib,
  pkgs,
  ...
}:

let
  imageMimeTypes = [
    # Common formats
    "image/jpeg"
    "image/jpg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/tiff"
    "image/svg+xml"

    # Modern formats
    "image/avif"
    "image/avif-sequence"
    "image/heic"
    "image/heif"
    "image/apng"
    "image/jxl"

    # Editing formats
    "image/vnd.adobe.photoshop"
    "image/x-xcf"
    "image/openraster"
    "application/psd"
    "application/photoshop"
    "application/x-krita"

    # Additional formats
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
in
{
  # ============================================================================
  # CONFIGURATION FILES
  # ============================================================================

  home.file = {
    ".config/waybar".source = ./home/waybar;
    ".config/mako".source = ./home/mako;
    ".config/Kvantum/Graphite".source = ./home/Graphite;

    # Optional configurations.
    # ".config/hypr".source = ./home/hyprland;
    # ".config/rofi".source = ./home/rofi;
    # ".config/quickshell".source = ./home/quickshell;
    # ".config/Vencord".source = ./home/Vencord;
  };

  # ============================================================================
  # FISH
  # ============================================================================

  programs.fish = {
    enable = true;

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

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_min_tabs = 2;

      # Active tab
      active_tab_foreground = "#000000";
      active_tab_background = "#ffffff";
      active_tab_font_style = "bold";

      # Inactive tabs
      inactive_tab_foreground = "#a1a1aa";
      inactive_tab_background = "#27272a";
      inactive_tab_font_style = "normal";

      # Tab bar background
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
  # XDG / DESKTOP ENTRIES
  # ============================================================================

  xdg.enable = true;

  xdg.desktopEntries = {
    # --------------------------------------------------------------------------
    # Thunar
    # --------------------------------------------------------------------------

    thunar = {
      name = "Thunar";
      exec = "thunar %U";
      noDisplay = true;
    };

    thunar-bulk-rename = {
      name = "Thunar Bulk Rename";
      exec = "thunar --bulk-rename %F";
      noDisplay = true;
    };

    thunar-settings = {
      name = "Thunar Settings";
      exec = "thunar-settings";
      noDisplay = true;
    };

    thunar-volman-settings = {
      name = "Thunar Volume Manager";
      exec = "thunar-volman-settings";
      noDisplay = true;
    };

    # --------------------------------------------------------------------------
    # File Roller
    # --------------------------------------------------------------------------

    "org.gnome.FileRoller" = {
      name = "File Roller";
      exec = "file-roller %U";
      noDisplay = true;
    };

    # --------------------------------------------------------------------------
    # GTK4 utilities
    # --------------------------------------------------------------------------

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

    # --------------------------------------------------------------------------
    # Neovim
    # --------------------------------------------------------------------------

    neovim = {
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

    # --------------------------------------------------------------------------
    # qView
    # --------------------------------------------------------------------------

    qview = {
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

      mimeType = imageMimeTypes;
    };

    # --------------------------------------------------------------------------
    # Kitty
    # --------------------------------------------------------------------------

    kitty = {
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
  };

  # ============================================================================
  # XDG / DEFAULT APPLICATIONS
  # ============================================================================

  xdg.mimeApps = {
    enable = true;

    defaultApplications = (lib.genAttrs imageMimeTypes (_: "qview.desktop")) // {
      # Directories
      "inode/directory" = [ "thunar.desktop" ];

      # Text editor
      "text/plain" = [ "neovim.desktop" ];
      "text/x-c" = [ "neovim.desktop" ];
      "text/x-c++" = [ "neovim.desktop" ];
      "text/x-python" = [ "neovim.desktop" ];
      "text/x-java" = [ "neovim.desktop" ];
      "text/x-shellscript" = [ "neovim.desktop" ];
      "text/x-makefile" = [ "neovim.desktop" ];
      "application/json" = [ "neovim.desktop" ];
      "application/xml" = [ "neovim.desktop" ];

      # Compressed archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
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
  # CLIPHIST CLEANUP
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
}
