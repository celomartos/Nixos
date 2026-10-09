{ config, pkgs, waybar, ... }:

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

 # home.file.".config/hypr".source = ./home/hyprland;
 # home.file.".config/waybar".source = ./home/waybar;
  home.file.".config/rofi".source = ./home/rofi;
  home.file.".config/mako".source = ./home/mako;
  home.file.".config/cava".source = ./home/cava;
  home.file.".config/Kvantum/Graphite".source = ./home/Graphite;
  home.file.".local/share/themes/Graphite-Dark".source = ./home/Graphite-Dark;

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
      font_family = "JetBrainsMono Nerd Font";
      font_size = 14;
      background_opacity = "0.85";
      background_blur = "0";
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

xdg.desktopEntries.neovim = {
  name = "Neovim";
  genericName = "Text Editor";
  exec = "kitty nvim %F";
  terminal = false;
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

xdg.mimeApps = {
  enable = true;

  defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
    #text editor
    "text/plain" = [ "neovim.desktop" ];
    "text/x-c" = [ "neovim.desktop" ];
    "text/x-c++" = [ "neovim.desktop" ];
    "text/x-python" = [ "neovim.desktop" ];
    "text/x-java" = [ "neovim.desktop" ];
    "text/x-shellscript" = [ "neovim.desktop" ];
    "text/x-makefile" = [ "neovim.desktop" ];
    "application/json" = [ "neovim.desktop" ];
    "application/xml" = [ "neovim.desktop" ];

    #compacted archives
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
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  # ============================================================================
  # STEMIO
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

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 23;
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
    jq
    socat
    android-tools
    yt-dlp

    # --------------------------------------------------------------------------
    # Development
    # --------------------------------------------------------------------------

    gdb
    cmake
    gnumake
    neovim
    git
    luaPackages.tree-sitter-cli
    lazygit
    fd
    ripgrep
    fzf
    clang
    clang-tools
    lua-language-server
    pnpm
    electron
    ydotool
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
    hyprpaper
    waybar.packages.${pkgs.stdenv.hostPlatform.system}.default

    # --------------------------------------------------------------------------
    # GTK / Qt
    # --------------------------------------------------------------------------

    nwg-look
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    gtk3
    gtk4
    tela-icon-theme
    kdePackages.breeze
    kdePackages.breeze-gtk
    kdePackages.kcolorscheme
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum

    # --------------------------------------------------------------------------
    # File management / utilities
    # --------------------------------------------------------------------------

    qbittorrent
    qview
    xfce4-settings
    libgsf
    poppler
    webp-pixbuf-loader
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

    proton-vpn
    brave-origin

    # --------------------------------------------------------------------------
    # Gaming
    # --------------------------------------------------------------------------

    (pkgs.discord.override {
    withVencord = true;
    })
    prismlauncher
    protonup-qt
    mangohud
    lutris
    wine
    appimage-run
    lact
    hydralauncher

    # --------------------------------------------------------------------------
    # Graphics / Vulkan
    # --------------------------------------------------------------------------

    vulkan-tools
    mesa-demos
    gimp
    hyprshot
    slurp
    obs-studio

    # OBS plugins.
    obs-studio-plugins.obs-pipewire-audio-capture
    obs-studio-plugins.obs-scene-as-transition
    obs-studio-plugins.obs-vkcapture
  ];
}
