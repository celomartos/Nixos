{ ... }:

{
  imports = [
    ./home/nixvim/default.nix
    ./programs.nix
    ./packages.nix
  ];

  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  home.username = "celin";
  home.homeDirectory = "/home/celin";

  home.stateVersion = "26.05";
}
