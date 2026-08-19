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
          set_color "#FFFFFF"
          echo -n "in "(prompt_pwd)
          set_color normal
          echo -n " > "
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
      fastfetch
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
      background_opacity = "0.6";
      background_blur = "0";
    };
  };

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  # ============================================================================
  # FASTFETCH
  # ============================================================================

  home.file.".config/fastfetch/fastfetch.png".source = /home/celin/Nixos/home/assets/fastfetch.jpg;
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

  { "type": "packages",
	  "key": "Pkgs    | ",
	  "keyIcon": ""
	},

	{ "type": "wm",
	  "key": "WM      | ",
	  "keyIcon": ""
	},

  {
    "type": "uptime",
    "key": "Uptime  | ",
    "keyIcon": ""
  },

	{ "type": "custom",
	  "format": "────────────────────────────"
	},

	{ "type": "gpu",
	  "key": "GPU     | ",
	  "keyIcon": ""
        },

	{ "type": "cpu",
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
     },
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
    lazygit
    fd
    ripgrep
    fzf


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
    stremio-linux-shell

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
