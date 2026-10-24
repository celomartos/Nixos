{ config, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.source = pkgs.path;

    # ============================================================================
    # EDITOR DEFAULTS
    # ============================================================================

    opts = {
      termguicolors = true;
      clipboard = "unnamedplus";
      confirm = true;
      number = true;
      relativenumber = false;
      autoindent = true;
      smartindent = true;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      shiftround = true;
    };

    # ============================================================================
    # THEME
    # ============================================================================

    colorscheme = "oxocarbon";
    extraPlugins = [ pkgs.vimPlugins.oxocarbon-nvim ];

    plugins = {
      # ============================================================================
      # LANGUAGE SERVERS
      # ============================================================================

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

      # ============================================================================
      # FILE SEARCH AND NAVIGATION
      # ============================================================================

      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
        };
      };

      # ============================================================================
      # SYNTAX HIGHLIGHTING AND INDENTATION
      # ============================================================================

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

      # ============================================================================
      # COMPLETION AND SNIPPETS
      # ============================================================================

      cmp-nvim-lsp.enable = true;
      cmp_luasnip.enable = true;
      luasnip.enable = true;
      cmp-path.enable = true;
      cmp-buffer.enable = true;

      # ============================================================================
      # GIT SIGNS AND STATUS LINE
      # ============================================================================

      gitsigns.enable = true;
      lualine.enable = true;

      # ============================================================================
      # FORMAT CODE WHEN SAVING
      # ============================================================================

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

      # nvim-cmp sources, snippet expansion, and completion keybindings.
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

    # ============================================================================
    # C AND C++ MAIN SNIPPETS
    # ============================================================================

    extraConfigLua = ''
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("c", {
        s("main", {
          t({ "#include <stdio.h>", "", "int main(void) {", "    " }),
          i(1),
          t({ "", "    return 0;", "}" }),
          i(0),
        }),
      })

      ls.add_snippets("cpp", {
        s("main", {
          t({ "#include <iostream>", "", "int main() {", "    " }),
          i(1),
          t({ "", "    return 0;", "}" }),
          i(0),
        }),
      })

      -- Let the terminal provide Neovim's window background.
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

      -- Restore the cursor to the last position used in an existing file.
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = "*",
        callback = function(event)
          local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
          local line_count = vim.api.nvim_buf_line_count(event.buf)
          if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end,
      })
    '';

    # ============================================================================
    # KEYBINDINGS
    # ============================================================================

    keymaps = [
      { mode = "i"; key = "<C-l>"; action = "<cmd>lua require(\"luasnip\").jump(1)<CR>"; options.desc = "Next snippet placeholder"; }
      { mode = "i"; key = "<C-h>"; action = "<cmd>lua require(\"luasnip\").jump(-1)<CR>"; options.desc = "Previous snippet placeholder"; }
      { mode = "n"; key = "gd"; action = "<cmd>lua vim.lsp.buf.definition()<CR>"; options.desc = "Go to definition"; }
      { mode = "n"; key = "gr"; action = "<cmd>lua vim.lsp.buf.references()<CR>"; options.desc = "Find references"; }
      { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Hover documentation"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Rename symbol"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code action"; }
      { mode = "n"; key = "<leader>e"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; options.desc = "Show diagnostic"; }
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; options.desc = "Clear search highlighting"; }
    ];

    # ============================================================================
    # TOOLS USED BY LANGUAGE SERVERS AND FORMATTERS
    # ============================================================================

    extraPackages = with pkgs; [
      cargo
      rustc
      stylua
      rustfmt
      nixfmt
    ];
  };
}
