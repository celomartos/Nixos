{ config, pkgs, ... }:

{
  # Git signs and status line.
  programs.nixvim.plugins = {
      gitsigns = {
        enable = true;
        settings = {
          trouble = true;
          current_line_blame = false;
          on_attach = ''
            function(bufnr)
              local gs = require("gitsigns")

              local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
              end

              -- Navigation between hunks
              local function next_hunk()
                if vim.wo.diff then
                  vim.cmd.normal({ "]c", bang = true })
                else
                  gs.nav_hunk("next")
                end
              end

              local function prev_hunk()
                if vim.wo.diff then
                  vim.cmd.normal({ "[c", bang = true })
                else
                  gs.nav_hunk("prev")
                end
              end

              map("n", "]h", next_hunk, "Next git hunk")
              map("n", "[h", prev_hunk, "Previous git hunk")
              map("n", "]c", next_hunk, "Next git hunk")
              map("n", "[c", prev_hunk, "Previous git hunk")

              -- Diff and hunk preview
              map("n", "<leader>hp", gs.preview_hunk, "Preview git hunk")
              map("n", "<leader>hd", gs.preview_hunk_inline, "Diff current line/hunk inline")
              map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff file against HEAD")

              -- Explicit restoration (never automatic)
              map("n", "<leader>hr", gs.reset_hunk, "Reset git hunk")
              map("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
              end, "Reset selected lines")
              map("n", "<leader>hR", gs.reset_buffer, "Reset entire buffer")

              -- Line history and blame
              map("n", "<leader>hb", function()
                gs.blame_line({ full = true })
              end, "Line commit history (blame)")
              map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame virtual text")

              -- Quickfix integration
              map("n", "<leader>hq", function()
                gs.setqflist("all")
              end, "Send hunks to quickfix")
            end
          '';
        };
      };

      lualine.enable = true;
  };
}
