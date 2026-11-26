{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ydotool daemon
  systemd.user.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold --socket-path=%t/.ydotool_socket";
      Restart = "on-failure";
    };
  };

  services.ratbagd.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  security.polkit.enablePkexecWrapper = true;

  services.displayManager.regreet = {
    enable = true;

    theme = {
      name = "Graphite-Dark";

      package = pkgs.runCommand "graphite-dark-theme" { } ''
        mkdir -p $out/share/themes
        ln -s ${../home/Graphite-Dark} $out/share/themes/Graphite-Dark
      '';
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "graphite-dark";
      package = pkgs.graphite-cursors;
    };
  };

  services.gnome.gnome-keyring.enable = true;

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
}
