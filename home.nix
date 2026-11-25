{ ... }:

{
  imports = [
    ./home/nixvim/default.nix
    ./home/programs.nix
    ./home/packages.nix
  ];

  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  home.username = "celin";
  home.homeDirectory = "/home/celin";

  home.stateVersion = "26.05";
}
