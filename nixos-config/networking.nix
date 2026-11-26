{ pkgs, ... }:

{
  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  networking.firewall.enable = true;

  # ============================================================================
  # RETHINKDNS
  # ============================================================================

  services.dnsproxy = {
    enable = true;

    settings = {
      # RethinkDNS personalizado com suas blocklists.
      upstream = [
        "https://sky.rethinkdns.com/1:IBqAAAAIEAAAgA=="
      ];

      # Bootstrap DNS para resolver o endereço do RethinkDNS.
      bootstrap = [
        "9.9.9.9:53"
        "149.112.112.112:53"
      ];

      # Escuta somente conexões locais.
      listen-addrs = [
        "127.0.0.1"
        "::1"
      ];

      listen-ports = [ 53 ];
    };
  };

  # Utiliza o dnsproxy como resolvedor do sistema.
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services.resolved.enable = false;

}
