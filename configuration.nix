{
  pkgs,
  nixpkgs-stable,
  ...
}:

let
  pkgs-stable = import nixpkgs-stable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in

{
  imports = [
    /etc/nixos/hardware-configuration.nix

    ./nixos-config/boot.nix
    ./nixos-config/networking.nix
    ./nixos-config/desktop.nix
    ./nixos-config/audio.nix
    ./nixos-config/hardware.nix
    ./nixos-config/gaming.nix
    ./nixos-config/flatpak.nix
    ./nixos-config/services.nix
    ./nixos-config/global-pkgs.nix
  ];

  # ============================================================================
  # NIX
  # ============================================================================

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 4d";
  };

  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.backupFileExtension = "backup";

  home-manager.extraSpecialArgs = {
    inherit pkgs-stable;
  };

  home-manager.users.celin = import ./home-manager/home.nix;

  # ============================================================================
  # LOCALE / TIMEZONE
  # ============================================================================

  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "br-abnt2";

  # ============================================================================
  # USER
  # ============================================================================

  users.users.celin = {
    isNormalUser = true;
    description = "celin";

    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "libvirtd"
    ];
  };

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  system.stateVersion = "26.05";
}
