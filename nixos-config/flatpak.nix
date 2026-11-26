{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    packages = [
      "org.vinegarhq.Sober"
      "com.stremio.Stremio"
      "com.usebottles.bottles"
      "com.discordapp.Discord"
    ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };

  # Flathub remote
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];

    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Graphite theme for Flatpaks
  systemd.user.services.flatpak-graphite-theme = {
    description = "Configurar tema Graphite nos Flatpaks";
    wantedBy = [ "default.target" ];

    path = with pkgs; [
      coreutils
      flatpak
    ];

    script = ''
      themeDir="$HOME/.local/share/themes/Graphite-Dark"

      if [ -d "$themeDir" ] && [ ! -L "$themeDir" ]; then
        chmod -R u+w "$themeDir"
      fi

      rm -rf "$themeDir"
      mkdir -p "$HOME/.local/share/themes"

      cp -R ${../home/Graphite-Dark} "$themeDir"
      chmod -R u+w "$themeDir"

      flatpak override --user \
        --filesystem=$HOME/.themes:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-config/Kvantum:ro \
        --env=GTK_THEME=Graphite-Dark \
        --env=QT_STYLE_OVERRIDE=kvantum \
        --env=TZ=America/Sao_Paulo
    '';

    serviceConfig.Type = "oneshot";
  };

  # Bottles Libadwaita colors
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
}
