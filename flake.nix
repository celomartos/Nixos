{
  description = "NixOS configuration for celin";

  # ============================================================================
  # FLAKE SETTINGS
  # ============================================================================

  # Binary caches used when operating through this flake.
  nixConfig = {
    extra-substituters = [
      "https://nixpkgs.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  # ============================================================================
  # FLAKE INPUTS
  # ============================================================================

  inputs = {
    # Package channels used by the system.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    waybar = {
      url = "github:Alexays/Waybar/e17c0d9";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim configuration module.
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional NixOS modules.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

  };

  # ============================================================================
  # FLAKE OUTPUTS
  # ============================================================================

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      waybar,
      nixvim,
      home-manager,
      nix-flatpak,
      lanzaboote,
      chaotic,
      ...
    }:
    {
      # Main NixOS system configuration.
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # Pass additional inputs to configuration modules.
        specialArgs = {
          inherit nixpkgs-stable;
        };

        # Compose the system, Home Manager, and external modules.
        modules = [
          ./configuration.nix

          { nixpkgs.overlays = [ waybar.overlays.waybar ]; }

          home-manager.nixosModules.home-manager
          { home-manager.sharedModules = [ nixvim.homeModules.nixvim ]; }

          nix-flatpak.nixosModules.nix-flatpak
          lanzaboote.nixosModules.lanzaboote
          chaotic.nixosModules.default
        ];
      };
    };
}
