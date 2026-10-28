{ config, pkgs, ... }:

{
  # Completion sources and snippets.
  programs.nixvim.plugins = {
      cmp-nvim-lsp.enable = true;

      cmp_luasnip.enable = true;

      luasnip.enable = true;

      cmp-path.enable = true;

      cmp-buffer.enable = true;

      cmp = {
        enable = true;
        autoEnableSources = false;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
        };
      };
  };
}
