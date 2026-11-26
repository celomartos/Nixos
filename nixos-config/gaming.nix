{
  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  # programs.gamemode.enable = true;
}
