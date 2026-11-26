{ pkgs, ... }:

{
  # ============================================================================
  # SYSTEM LOGGING
  # ============================================================================

  services.journald.settings.Journal = {
    SystemMaxUse = "500M";
    RuntimeMaxUse = "100M";
  };

  # ============================================================================
  # ANANICY
  # ============================================================================

  services.ananicy = {
    enable = true;

    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # ============================================================================
  # VIRTUALIZATION
  # ============================================================================

  virtualisation.libvirtd.enable = true;

  programs.virt-manager.enable = true;
}
