{ config, pkgs, ... }:

{
  # Language servers and diagnostics.
  programs.nixvim.plugins = {
    lsp = {
      enable = true;
      servers = {
        lua_ls = {
          enable = true;
          package = pkgs.lua-language-server;
        };
        nil_ls = {
          enable = true;
          settings.nix.flake.autoArchive = false;
        };
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
          settings = {
            checkOnSave = true;
            cargo.allFeatures = false;
            inlayHints = {
              enable = true;
              bindingModeHints.enable = false;
            };
          };
        };
        clangd = {
          enable = true;
          package = pkgs.clang-tools;
        };
      };
    };

    trouble.enable = true;

    todo-comments.enable = true;
  };
}
