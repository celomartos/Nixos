{
  description = "NixOS configuration for celin";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      nix-flatpak,
      lanzaboote,
      waybar,
      ...
    }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {

        system = "x86_64-linux";

        specialArgs = {
          inherit nixpkgs-stable waybar;
        };

        modules = [
          ./configuration.nix

          home-manager.nixosModules.home-manager

          nix-flatpak.nixosModules.nix-flatpak

          lanzaboote.nixosModules.lanzaboote
        ];
      };
    };
}
