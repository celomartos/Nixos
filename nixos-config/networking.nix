{ pkgs, ... }:

{
  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  networking.firewall.enable = true;

  services.nextdns = {
    enable = true;

    arguments = [
      "-config"
      "557a3a"
    ];
  };

  systemd.services.nextdns-activate = {
    after = [ "nextdns.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;

    script = ''
      ${pkgs.nextdns}/bin/nextdns activate
    '';
  };
}
