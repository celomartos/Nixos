{ pkgs, ... }:

{
  # ============================================================================
  # APPIMAGE
  # ============================================================================

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # ============================================================================
  # FONTS
  # ============================================================================

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    texlivePackages.opensans
    noto-fonts
    texlivePackages.droid
    texlivePackages.roboto
    nerd-fonts.monaspace
    inter
  ];

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Network and security
    sbctl

    # Archive and file manager
    gdk-pixbuf

    # Windows and AppImage compatibility
    fuse3
    glib
  ];

  # ============================================================================
  # NIX-LD
  # ============================================================================

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
  # SESSION VARIABLES
  # ============================================================================

  environment.sessionVariables = {
    MESA_SHADER_CACHE_MAX_SIZE = "12G";
    GSK_RENDERER = "gl";
  };

  environment.pathsToLink = [
    "/share/thumbnailers"
  ];
}
