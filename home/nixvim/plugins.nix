{ config, pkgs, ... }:

{
  # Remaining editor plugins.
  programs.nixvim.plugins = {
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
        };
      };

      persistence = {
        enable = true;
        settings = {
          need = 1;
          branch = true;
        };
      };

      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          c
          cpp
          json
          lua
          markdown
          nix
          python
          rust
          toml
          vim
          yaml
        ];
      };

      nvim-autopairs.enable = true;

      mini-surround.enable = true;

      flash = {
        enable = true;
        settings = {
          modes = {
            char.enabled = false;
            search.enabled = false;
          };
        };
      };

      comment.enable = true;

      which-key = {
        enable = true;
        settings.win = {
          col = -1;
          width.max = 55;
          padding = [
            0
            1
          ];
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            timeout_ms = 3000;
            lsp_format = "fallback";
          };
          formatters_by_ft = {
            c = [ "clang_format" ];
            cpp = [ "clang_format" ];
            lua = [ "stylua" ];
            rust = [ "rustfmt" ];
            nix = [ "nixfmt" ];
          };
        };
      };
  };
}
