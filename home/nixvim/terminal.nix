{ config, pkgs, ... }:

{
  # Integrated terminal.
  programs.nixvim.plugins = {
      toggleterm = {
        enable = true;
        callSetup = false;
      };
  };
}
