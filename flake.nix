{
  # ============================================================================
  # FLAKE
  # ============================================================================

  description = "NixOS configuration for celin";

  # ============================================================================
  # INPUTS
  # ============================================================================

  inputs = {

    # --------------------------------------------------------------------------
    # Nixpkgs
    # --------------------------------------------------------------------------

    # NixOS unstable provides newer packages and features.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # --------------------------------------------------------------------------
    # Home Manager
    # --------------------------------------------------------------------------

    # User-level configuration and package management.
    home-manager = {
      url = "github:nix-community/home-manager/master";

      # Use the same nixpkgs version as the system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # CachyOS Kernel
    # --------------------------------------------------------------------------

    # CachyOS-optimized Linux kernels.
    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";

    # --------------------------------------------------------------------------
    # Lanzaboote
    # --------------------------------------------------------------------------

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };

    # --------------------------------------------------------------------------
    # Flatpak
    # --------------------------------------------------------------------------

    # Declarative Flatpak management for NixOS.
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  # ============================================================================
  # OUTPUTS
  # ============================================================================

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      cachyos-kernel,
      nix-flatpak,
      lanzaboote,
      ...
    }:
    {
      # ------------------------------------------------------------------------
      # NixOS Configuration
      # ------------------------------------------------------------------------

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {

        # System architecture.
        system = "x86_64-linux";

        # ----------------------------------------------------------------------
        # Extra Arguments
        # ----------------------------------------------------------------------

        # Make the CachyOS kernel input available inside configuration.nix.
        specialArgs = {
          inherit cachyos-kernel;
        };

        # ----------------------------------------------------------------------
        # NixOS Modules
        # ----------------------------------------------------------------------

        modules = [
          # Main system configuration.
          ./configuration.nix

          # Home Manager integration.
          home-manager.nixosModules.home-manager

          # Declarative Flatpak support.
          nix-flatpak.nixosModules.nix-flatpak

          # Lanzaboote
          lanzaboote.nixosModules.lanzaboote
        ];
      };
    };
}
