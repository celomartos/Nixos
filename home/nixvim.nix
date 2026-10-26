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

      # ==========================================================================
      # COMPACT IN-EDITOR TERMINAL
      # ==========================================================================

      toggleterm = {
        enable = true;
        callSetup = false;
      };

      # ==========================================================================
      # DEBUGGING
      # ==========================================================================

      dap =
        let
          launchConfiguration = {
            type = "codelldb";
            request = "launch";
            name = "Launch executable";
            program.__raw = ''
              function()
                local defaultPath = vim.fn.getcwd() .. "/"
                if vim.bo.filetype == "rust" then
                  local root = vim.fs.root(0, "Cargo.toml") or vim.fn.getcwd()
                  defaultPath = root .. "/target/debug/"
                end
                return vim.fn.input("Path to executable: ", defaultPath, "file")
              end
            '';
            cwd = "\${workspaceFolder}";
            args = [ ];
            stopOnEntry = false;
          };
        in
        {
          enable = true;
          adapters.servers.codelldb = {
            port = "\${port}";
            executable = {
              command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter}/bin/codelldb";
              args = [
                "--port"
                "\${port}"
              ];
            };
          };
          configurations = {
            c = [ launchConfiguration ];
            cpp = [ launchConfiguration ];
            rust = [ launchConfiguration ];
          };
        };

      dap-ui = {
        enable = true;
        settings.layouts = [
          {
            elements = [ "scopes" ];
            size = 35;
            position = "right";
          }
        ];
      };

      # ==========================================================================
      # DIAGNOSTICS AND CODE NAVIGATION
      # ==========================================================================

      trouble.enable = true;

      # ============================================================================
      # TODO AND FIXME COMMENTS
      # ============================================================================

      todo-comments.enable = true;

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
      # AUTOMATIC PAIR COMPLETION
      # ============================================================================

      nvim-autopairs.enable = true;

      # ============================================================================
      # ADD, CHANGE, AND REMOVE SURROUNDING CHARACTERS
      # ============================================================================

      mini-surround.enable = true;

      # ============================================================================
      # CODE COMMENTS
      # ============================================================================

      comment.enable = true;

      # ============================================================================
      # KEYBINDING DISCOVERY
      # ============================================================================

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
      -- Save modified files when leaving insert mode.
      vim.api.nvim_create_autocmd("InsertLeave", {
        desc = "Save modified files after leaving insert mode",
        callback = function(event)
          local buf = event.buf
          if vim.bo[buf].buftype == ""
            and vim.bo[buf].modifiable
            and not vim.bo[buf].readonly
            and vim.bo[buf].modified
            and vim.api.nvim_buf_get_name(buf) ~= "" then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("silent update")
            end)
          end
        end,
      })

      -- Keep one small terminal panel available for shell commands and running code.
      local terminal_size = 10
      require("toggleterm").setup({
        size = terminal_size,
        direction = "horizontal",
        hide_numbers = true,
        persist_size = false,
        start_in_insert = true,
        close_on_exit = false,
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local ide_terminal
      local function toggle_ide_terminal()
        ide_terminal:toggle(terminal_size, "horizontal")
      end

      ide_terminal = Terminal:new({
        count = 1,
        direction = "horizontal",
        hidden = true,
        close_on_exit = false,
        on_open = function(term)
          vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
            buffer = term.bufnr,
            desc = "Leave terminal input mode",
          })
          vim.keymap.set("t", "<leader>tt", toggle_ide_terminal, {
            buffer = term.bufnr,
            desc = "Close terminal panel",
          })
        end,
      })

      vim.keymap.set("n", "<leader>tt", toggle_ide_terminal, {
        desc = "Toggle terminal panel",
        silent = true,
      })

      local function run_current_file()
        local file = vim.fn.expand("%:p")
        if file == "" or vim.bo.buftype ~= "" then
          vim.notify("Open a saved source file first", vim.log.levels.WARN)
          return
        end

        vim.cmd("update")

        local filetype = vim.bo.filetype
        local directory = vim.fn.fnamemodify(file, ":h")
        local shellescape = vim.fn.shellescape
        local command
        local prefix = "cd " .. shellescape(directory) .. " && "
        local source = shellescape(file)

        if filetype == "c" or filetype == "cpp" then
          local compiler = filetype == "c" and "clang" or "clang++"
          local executable = shellescape(vim.fn.tempname())
          command = prefix .. compiler .. " " .. source .. " -o " .. executable .. " && " .. executable
        elseif filetype == "lua" then
          command = prefix .. "lua " .. source
        elseif filetype == "rust" then
          local manifest = vim.fs.find("Cargo.toml", { path = directory, upward = true })[1]
          if manifest then
            local project_root = vim.fn.fnamemodify(manifest, ":h")
            command = "cd " .. shellescape(project_root) .. " && cargo run"
          else
            local executable = shellescape(vim.fn.tempname())
            command = prefix .. "rustc --edition=2021 " .. source .. " -o " .. executable .. " && " .. executable
          end
        else
          vim.notify("No run command configured for filetype: " .. filetype, vim.log.levels.WARN)
          return
        end

        if not ide_terminal:is_open() then
          ide_terminal:open(terminal_size, "horizontal")
        else
          ide_terminal:focus()
        end
        ide_terminal:send(command)
      end

      vim.api.nvim_create_user_command("RunCurrentFile", run_current_file, {})
      vim.keymap.set("n", "<leader>rr", run_current_file, {
        desc = "Run current source file",
        silent = true,
      })

      -- Open the debugger panel when a session starts and close it when the session ends.
      local dap = require("dap")
      local dapui = require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Start or continue debugging" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Set conditional breakpoint" })
      vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Stop debugging" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle debugger panel" })

      -- Add parentheses after accepting a function or method completion.
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())

      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("c", {
        s("main", {
          t({ "#include <stdio.h>", "", "int main(void) {", "  " }),
          i(1),
          t({ "", "  return 0;", "}" }),
          i(0),
        }),
      })

      ls.add_snippets("cpp", {
        s("main", {
          t({ "#include <iostream>", "", "int main() {", "  " }),
          i(1),
          t({ "", "  return 0;", "}" }),
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
          local win = vim.fn.bufwinid(event.buf)
          if mark[1] > 0 and mark[1] <= line_count and win ~= -1 and vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_set_cursor, win, mark)
          end
        end,
      })

      -- Close the Trouble list with Escape without changing other buffers.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "trouble",
        callback = function(event)
          local buf = event.buf
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.keymap.set("n", "<Esc>", function()
                require("trouble").close()
              end, {
                buffer = buf,
                desc = "Close Trouble",
                silent = true,
              })

              local win = vim.fn.bufwinid(buf)
              if win ~= -1 and vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
              end
            end
          end)
        end,
      })
    '';

    # ============================================================================
    # KEYBINDINGS
    # ============================================================================

    keymaps = [
      {
        mode = "i";
        key = "<C-l>";
        action = "<cmd>lua require(\"luasnip\").jump(1)<CR>";
        options.desc = "Next snippet placeholder";
      }
      {
        mode = "i";
        key = "<C-h>";
        action = "<cmd>lua require(\"luasnip\").jump(-1)<CR>";
        options.desc = "Previous snippet placeholder";
      }
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<CR>";
        options.desc = "Go to definition";
      }
      {
        mode = "n";
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<CR>";
        options.desc = "Find references";
      }
      {
        mode = "n";
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<CR>";
        options.desc = "Hover documentation";
      }
      {
        mode = "n";
        key = "<leader>rn";
        action = "<cmd>lua vim.lsp.buf.rename()<CR>";
        options.desc = "Rename symbol";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        options.desc = "Code action";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua vim.diagnostic.open_float()<CR>";
        options.desc = "Show diagnostic";
      }
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle focus=true<CR>";
        options.desc = "Toggle diagnostics list";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<CR>";
        options.desc = "Toggle buffer diagnostics";
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle focus=true<CR>";
        options.desc = "Toggle document symbols";
      }
      {
        mode = "n";
        key = "<leader>cl";
        action = "<cmd>Trouble lsp toggle focus=true win.position=right<CR>";
        options.desc = "Toggle LSP navigation";
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle focus=true<CR>";
        options.desc = "Toggle location list";
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle focus=true<CR>";
        options.desc = "Toggle quickfix list";
      }
      {
        mode = "n";
        key = "<leader>xt";
        action = "<cmd>Trouble todo toggle focus=true<CR>";
        options.desc = "Toggle TODO and FIXME list";
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>lua local ok, trouble = pcall(require, 'trouble'); if ok and trouble.is_open() then trouble.close() else vim.cmd('nohlsearch') end<CR>";
        options.desc = "Close Trouble or clear search highlighting";
      }
    ];

    # ============================================================================
    # DEVELOPMENT TOOLS
    # ============================================================================

    extraPackages = with pkgs; [
      # Compilers and runtimes used by RunCurrentFile.
      clang
      cargo
      lua
      rustc

      # Formatters and debugger adapter.
      nixfmt
      rustfmt
      stylua
      vscode-extensions.vadimcn.vscode-lldb.adapter
    ];
  };
}
