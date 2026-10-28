{ config, pkgs, ... }:

{
  # Language servers and diagnostics.
  programs.nixvim.plugins = {
      lsp = {
        enable = true;
        capabilities = ''
          capabilities = vim.tbl_deep_extend("force", capabilities, require('cmp_nvim_lsp').default_capabilities())
        '';
        servers = {
          lua_ls = {
            enable = true;
            package = pkgs.lua-language-server;
          };
          nil_ls = {
            enable = true;
            settings.nix.flake.autoArchive = true;
          };
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
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
