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
      sessionoptions = [
        "buffers"
        "curdir"
        "tabpages"
        "winsize"
        "help"
        "globals"
        "skiprtp"
        "folds"
      ];
    };

    # ============================================================================
    # THEME
    # ============================================================================

    colorscheme = "oxocarbon";
    extraPlugins = [
      pkgs.vimPlugins.oxocarbon-nvim
      pkgs.vimPlugins.nvim-nio
      pkgs.vimPlugins.catppuccin-nvim
      pkgs.vimPlugins.tokyonight-nvim
      pkgs.vimPlugins.kanagawa-nvim
      pkgs.vimPlugins.gruvbox-nvim
      pkgs.vimPlugins.vim-moonfly-colors
    ];

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
      # DASHBOARD AND QOL TOOLS
      # ============================================================================

      snacks = {
        enable = true;
        settings = {
          bigfile.enabled = false;
          notifier.enabled = false;
          quickfile.enabled = false;
          statuscolumn.enabled = false;
          words.enabled = false;

          picker.layout.preset = "telescope";

          picker.sources.explorer.layout = {
            preset = "sidebar";
            preview = false;
            layout = {
              width = 28;
              min_width = 28;
            };
          };

          picker.sources.explorer.actions.__raw = ''
            (function()
              local uv = vim.uv or vim.loop
              local state_file = vim.fn.stdpath("state") .. "/snacks-explorer-trash.json"

              local function notify(kind, message)
                Snacks.notify[kind](message, { title = "Explorer Trash" })
              end

              local function read_file(path)
                local fd = uv.fs_open(path, "r", 438)
                if not fd then return nil end
                local stat = uv.fs_fstat(fd)
                local data = stat and uv.fs_read(fd, stat.size, 0) or nil
                uv.fs_close(fd)
                return data
              end

              local function history()
                local data = read_file(state_file)
                if not data then return {} end
                local ok, state = pcall(vim.json.decode, data)
                if not ok or type(state) ~= "table" or state.version ~= 1 or type(state.items) ~= "table" then
                  return nil, "Trash history is corrupt; refusing changes: " .. state_file
                end
                for _, item in ipairs(state.items) do
                  if type(item) ~= "table" or type(item.original) ~= "string" or type(item.trash) ~= "string"
                    or type(item.identifier) ~= "string" or type(item.timestamp) ~= "number"
                    or type(item.type) ~= "string" then
                    return nil, "Trash history has an invalid entry; refusing changes: " .. state_file
                  end
                end
                return state.items
              end

              local function save(items)
                local dir = vim.fn.fnamemodify(state_file, ":h")
                if vim.fn.mkdir(dir, "p", 448) == 0 and vim.fn.isdirectory(dir) == 0 then
                  return false, "cannot create state directory: " .. dir
                end
                local temp = state_file .. ".tmp." .. uv.os_getpid() .. "." .. uv.hrtime()
                local fd, err = uv.fs_open(temp, "wx", 384)
                if not fd then return false, err end
                local data = vim.json.encode({ version = 1, items = items })
                local written, write_err = uv.fs_write(fd, data, 0)
                local ok = written == #data
                if not ok and not write_err then write_err = "short state write" end
                if ok and uv.fs_fsync then ok, write_err = uv.fs_fsync(fd) end
                uv.fs_close(fd)
                if not ok then
                  uv.fs_unlink(temp)
                  return false, write_err
                end
                local renamed, rename_err = uv.fs_rename(temp, state_file)
                if not renamed then
                  uv.fs_unlink(temp)
                  return false, rename_err
                end
                return true
              end

              local function decode_path(path)
                local decoded = path:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
                return decoded
              end

              local function trash_dirs(path)
                local dirs, seen = {}, {}
                local function add(dir)
                  if not seen[dir] then seen[dir] = true; dirs[#dirs + 1] = dir end
                end
                local data_home = vim.env.XDG_DATA_HOME
                if not data_home or data_home == "" then data_home = vim.env.HOME .. "/.local/share" end
                add(data_home .. "/Trash")
                local ok, passwd = pcall(uv.os_get_passwd)
                local uid, cursor = ok and passwd and passwd.uid, vim.fs.dirname(path)
                local first = uv.fs_stat(cursor)
                while first do
                  local stat = uv.fs_stat(cursor)
                  if not stat or stat.dev ~= first.dev then break end
                  if uid then
                    add(cursor .. "/.Trash-" .. uid)
                    add(cursor .. "/.Trash/" .. uid)
                  end
                  local parent = vim.fs.dirname(cursor)
                  if parent == cursor then break end
                  cursor = parent
                end
                return dirs
              end

              local function trash_entries(path)
                local entries = {}
                for _, dir in ipairs(trash_dirs(path)) do
                  local info_dir, files_dir = dir .. "/info", dir .. "/files"
                  local scan = uv.fs_scandir(info_dir)
                  while scan do
                    local name, kind = uv.fs_scandir_next(scan)
                    if not name then break end
                    if kind == "file" and name:match("%.trashinfo$") then
                      local info = info_dir .. "/" .. name
                      local content = read_file(info)
                      local encoded = content and content:match("[\r\n]Path=([^\r\n]+)")
                      if content and not encoded then encoded = content:match("^Path=([^\r\n]+)") end
                      local id = name:gsub("%.trashinfo$", "")
                      local trashed = files_dir .. "/" .. id
                      if encoded and vim.fs.normalize(decode_path(encoded)) == path and uv.fs_lstat(trashed) then
                        entries[#entries + 1] = {
                          original = path,
                          trash = trashed,
                          identifier = info,
                          timestamp = os.time(),
                          type = uv.fs_lstat(trashed).type,
                          content = content,
                        }
                      end
                    end
                  end
                end
                return entries
              end

              local function exists(path)
                return uv.fs_lstat(path) ~= nil
              end

              return {
                explorer_del = function(picker)
                  local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
                  paths = vim.tbl_filter(function(path) return path and path ~= "" end, paths)
                  if #paths == 0 then notify("warn", "No Explorer item selected"); return end
                  local items, err = history()
                  if not items then notify("error", err); return end
                  local label = #paths == 1 and vim.inspect(paths[1]) or (#paths .. " selected items")
                  vim.api.nvim_echo({ {
                    "Move " .. label .. " to system trash? [ENTER confirms; ESC cancels]",
                    "Question",
                  } }, false, {})
                  local ok, key = pcall(vim.fn.getcharstr)
                  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
                  if not ok or (key ~= "\r" and key ~= "\n") then
                    notify("info", "Trash cancelled"); return
                  end

                  local moved, failures = 0, {}
                  for _, path in ipairs(paths) do
                    path = vim.fs.normalize(path)
                    local stat = uv.fs_lstat(path)
                    local before, old = trash_entries(path), {}
                    for _, entry in ipairs(before) do old[entry.identifier .. "\0" .. entry.content] = true end
                    local commands = {
                      { "trash", path }, { "gio", "trash", path },
                      { "kioclient5", "move", path, "trash:/" }, { "kioclient", "move", path, "trash:/" },
                    }
                    local trashed, errors = false, {}
                    for _, command in ipairs(commands) do
                      if vim.fn.executable(command[1]) == 1 then
                        local ok, output = pcall(vim.fn.system, command)
                        if ok and vim.v.shell_error == 0 then trashed = true; break end
                        output = ok and output or tostring(output)
                        errors[#errors + 1] = command[1] .. ": " .. (output ~= "" and output or "command failed")
                      end
                    end
                    if #errors == 0 and not trashed then errors[1] = "no system trash command found" end
                    if trashed then
                      local found
                      for _, entry in ipairs(trash_entries(path)) do
                        if not old[entry.identifier .. "\0" .. entry.content] then found = entry; break end
                      end
                      if found and stat then
                        found.timestamp = os.time()
                        items[#items + 1] = found
                        local saved, save_err = save(items)
                        if saved then
                          moved = moved + 1
                        else
                          failures[#failures + 1] = vim.inspect(path) .. ": trashed, but undo history save failed: " .. tostring(save_err)
                        end
                      else
                        failures[#failures + 1] = vim.inspect(path) .. ": trashed, but recoverable trash metadata was not found"
                      end
                      Snacks.bufdelete({ file = path, force = true })
                      require("snacks.explorer.tree"):refresh(vim.fs.dirname(path))
                    else
                      failures[#failures + 1] = vim.inspect(path) .. ": " .. table.concat(errors, "; ")
                    end
                  end
                  picker.list:set_selected()
                  require("snacks.explorer.actions").update(picker)
                  if moved > 0 then notify("info", ("Moved %d item(s) to system trash"):format(moved)) end
                  if #failures > 0 then notify("error", "Trash operation issue:\n" .. table.concat(failures, "\n")) end
                end,

                explorer_undo = function(picker)
                  local items, err = history()
                  if not items then notify("error", err); return end
                  if #items == 0 then notify("info", "No Explorer trash history"); return end
                  for index = #items, 1, -1 do
                    local item = items[index]
                    if item.original:sub(1, 1) ~= "/" then
                      notify("error", "Invalid original path; kept in history")
                      return
                    elseif not exists(item.trash) then
                      notify("warn", "Trash item missing or expired; kept in history: " .. item.original)
                    elseif not vim.tbl_contains(vim.tbl_map(function(entry)
                      return entry.identifier .. "\0" .. entry.trash
                    end, trash_entries(item.original)), item.identifier .. "\0" .. item.trash) then
                      notify("warn", "Trash metadata missing or mismatched; kept in history: " .. item.original)
                    else
                      local parent = vim.fs.dirname(item.original)
                      if not uv.fs_stat(parent) or uv.fs_stat(parent).type ~= "directory" then
                        notify("warn", "Original directory unavailable; kept in history: " .. parent)
                      elseif exists(item.original) then
                        notify("error", "Restore conflict; path already exists, history kept: " .. item.original)
                        return
                      else
                        local stat = uv.fs_lstat(item.trash)
                        if not stat or stat.type ~= item.type then
                          notify("error", "Trash item type changed; kept in history: " .. item.original)
                          return
                        end
                        if vim.fn.executable("mv") ~= 1 then
                          notify("error", "Cannot restore safely: `mv` unavailable; history kept")
                          return
                        end
                        local ok = pcall(vim.fn.system, { "mv", "-nT", "--", item.trash, item.original })
                        if not ok or vim.v.shell_error ~= 0 or exists(item.trash) then
                          notify("error", "Restore failed or destination appeared; history kept: " .. item.original)
                          return
                        end
                        table.remove(items, index)
                        local saved, save_err = save(items)
                        require("snacks.explorer.tree"):refresh(parent)
                        require("snacks.explorer.actions").update(picker)
                        if saved then
                          notify("info", "Restored: " .. item.original)
                        else
                          notify("error", "Restored, but history update failed: " .. tostring(save_err))
                        end
                        return
                      end
                    end
                  end
                  notify("warn", "No restorable trash items; history preserved")
                end,
              }
            end)()
          '';

          picker.sources.explorer.win.list.keys.U = "explorer_undo";

          explorer = {
            enabled = true;
            replace_netrw = true;
            trash = true;
          };

          dashboard = {
            enabled = true;
            width = 62;
            row = null;
            col = null;
            pane_gap = 4;

            preset = {
              keys = [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find File";
                  action = ":lua Snacks.picker.files()";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New File";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find Text";
                  action = ":lua Snacks.picker.grep()";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent Files";
                  action = ":lua Snacks.picker.recent()";
                }
                {
                  icon = "󰉼 ";
                  key = "t";
                  desc = "Themes";
                  action = ":NixvimThemePicker";
                }
                {
                  icon = " ";
                  key = "s";
                  desc = "Restore Session";
                  action = ":lua require('persistence').load()";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            };

            sections = [
              {
                section = "header";
                padding = 2;
              }
              {
                text = [
                  {
                    __raw = "{ '— Modern Neovim Environment —', hl = 'Comment' }";
                  }
                ];
                align = "center";
                padding = 1;
              }
              {
                icon = " ";
                title = "Atalhos";
                section = "keys";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Arquivos Recentes";
                section = "recent_files";
                indent = 2;
                padding = 1;
                limit = 5;
              }
              {
                icon = " ";
                title = "Projetos";
                section = "projects";
                indent = 2;
                padding = 1;
                limit = 4;
              }

              # Rodapé decorativo: não depende do lazy.nvim.
              {
                text = [
                  {
                    __raw = "{ 'Neovim • NixOS', hl = 'Comment' }";
                  }
                ];
                align = "center";
                padding = 1;
              }
            ];
          };
        };
      };

      # ============================================================================
      # SESSION MANAGEMENT
      # ============================================================================

      persistence = {
        enable = true;
        settings = {
          need = 1;
          branch = true;
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
            elements = [
              {
                id = "scopes";
                size = 0.75;
              }
              {
                id = "watches";
                size = 0.25;
              }
            ];
            size = 40;
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
      # FAST CODE NAVIGATION
      # ============================================================================

      flash = {
        enable = true;
        settings = {
          modes = {
            char.enabled = false;
            search.enabled = false;
          };
        };
      };

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

      local function send_to_ide_terminal(cmd)
        if not ide_terminal:is_open() then
          ide_terminal:open(terminal_size, "horizontal")
        else
          ide_terminal:focus()
        end
        ide_terminal:send(cmd)
      end

      local function show_build_diagnostics(title, lines)
        local current_qf = vim.fn.getqflist({ title = 1 })
        local action = (current_qf.title and current_qf.title:match("^Build: ")) and "r" or " "
        vim.fn.setqflist({}, action, {
          title = title,
          lines = lines,
        })
        local opened_trouble = false
        local ok_trouble, trouble = pcall(require, "trouble")
        if ok_trouble then
          local ok_open = pcall(function()
            trouble.open("qflist")
          end)
          if ok_open and trouble.is_open() then
            opened_trouble = true
          end
        end
        if not opened_trouble then
          vim.cmd("botright copen 8")
        end
      end

      local function clear_build_diagnostics()
        local current_qf = vim.fn.getqflist({ title = 1 })
        if current_qf.title and current_qf.title:match("^Build: ") then
          vim.fn.setqflist({}, "r", { title = "Build: clean", items = {} })
          vim.cmd("cclose")
          pcall(function()
            local ok_trouble, trouble = pcall(require, "trouble")
            if ok_trouble and trouble.is_open() then
              trouble.close()
            end
          end)
        end
      end

      local function run_current_file()
        local file = vim.fn.expand("%:p")
        if file == "" or vim.bo.buftype ~= "" then
          vim.notify("Open a saved source file first", vim.log.levels.WARN)
          return
        end

        if vim.bo.modified then
          vim.cmd("silent update")
        end

        local filetype = vim.bo.filetype
        local directory = vim.fn.fnamemodify(file, ":h")
        local filename = vim.fn.fnamemodify(file, ":t")

        if filetype == "c" or filetype == "cpp" then
          local compiler = filetype == "c" and "clang" or "clang++"
          local executable = vim.fn.tempname()
          vim.notify("Compiling " .. filename .. "...", vim.log.levels.INFO)

          vim.system(
            { compiler, file, "-o", executable },
            { cwd = directory, text = true },
            vim.schedule_wrap(function(obj)
              if obj.code ~= 0 then
                local raw_output = (obj.stderr or "") .. "\n" .. (obj.stdout or "")
                local lines = vim.split(raw_output, "\n", { trimempty = true })
                show_build_diagnostics("Build: " .. filename, lines)
                vim.notify("Compilation failed for " .. filename, vim.log.levels.ERROR)
                pcall(vim.fn.delete, executable)
              else
                clear_build_diagnostics()
                local run_cmd = "cd " .. vim.fn.shellescape(directory) .. " && "
                  .. vim.fn.shellescape(executable) .. "; rm -f " .. vim.fn.shellescape(executable)
                send_to_ide_terminal(run_cmd)
              end
            end)
          )
        elseif filetype == "rust" then
          local manifest = vim.fs.find("Cargo.toml", { path = directory, upward = true })[1]
          if manifest then
            local project_root = vim.fn.fnamemodify(manifest, ":h")
            vim.notify("Checking Cargo project...", vim.log.levels.INFO)
            vim.system(
              { "cargo", "check", "--message-format=short" },
              { cwd = project_root, text = true },
              vim.schedule_wrap(function(obj)
                if obj.code ~= 0 then
                  local raw_output = (obj.stderr or "") .. "\n" .. (obj.stdout or "")
                  local lines = vim.split(raw_output, "\n", { trimempty = true })
                  show_build_diagnostics("Build: Cargo (" .. vim.fn.fnamemodify(project_root, ":t") .. ")", lines)
                  vim.notify("Cargo check failed", vim.log.levels.ERROR)
                else
                  clear_build_diagnostics()
                  local run_cmd = "cd " .. vim.fn.shellescape(project_root) .. " && cargo run"
                  send_to_ide_terminal(run_cmd)
                end
              end)
            )
          else
            local executable = vim.fn.tempname()
            vim.notify("Compiling " .. filename .. "...", vim.log.levels.INFO)
            vim.system(
              { "rustc", "--edition=2021", "--error-format=short", file, "-o", executable },
              { cwd = directory, text = true },
              vim.schedule_wrap(function(obj)
                if obj.code ~= 0 then
                  local raw_output = (obj.stderr or "") .. "\n" .. (obj.stdout or "")
                  local lines = vim.split(raw_output, "\n", { trimempty = true })
                  show_build_diagnostics("Build: " .. filename, lines)
                  vim.notify("rustc compilation failed for " .. filename, vim.log.levels.ERROR)
                  pcall(vim.fn.delete, executable)
                else
                  clear_build_diagnostics()
                  local run_cmd = "cd " .. vim.fn.shellescape(directory) .. " && "
                    .. vim.fn.shellescape(executable) .. "; rm -f " .. vim.fn.shellescape(executable)
                  send_to_ide_terminal(run_cmd)
                end
              end)
            )
          end
        elseif filetype == "lua" then
          clear_build_diagnostics()
          local run_cmd = "cd " .. vim.fn.shellescape(directory) .. " && lua " .. vim.fn.shellescape(file)
          send_to_ide_terminal(run_cmd)
        else
          vim.notify("No run command configured for filetype: " .. filetype, vim.log.levels.WARN)
        end
      end

      vim.api.nvim_create_user_command("RunCurrentFile", run_current_file, {})
      vim.keymap.set("n", "<leader>rr", run_current_file, {
        desc = "Run current source file",
        silent = true,
      })

      -- Open the debugger panel when a session starts and close it when the session ends.
      local dap = require("dap")
      local dapui = require("dapui")

      local function close_debugger()
        dapui.close()
      end

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = close_debugger
      dap.listeners.before.event_exited["dapui_config"] = close_debugger
      dap.listeners.before.disconnect["dapui_config"] = close_debugger

      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Start or continue debugging" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Set conditional breakpoint" })
      vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dq", function()
        dap.terminate()
        close_debugger()
      end, { desc = "Stop debugging" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle debugger panel" })
      vim.keymap.set({ "n", "v" }, "<leader>de", function()
        dapui.eval()
      end, { desc = "Evaluate expression under cursor" })
      vim.keymap.set("n", "<leader>dh", function()
        require("dap.ui.widgets").hover()
      end, { desc = "Inspect variable under cursor" })
      vim.keymap.set("n", "<leader>ds", function()
        local widgets = require("dap.ui.widgets")
        widgets.centered_float(widgets.scopes)
      end, { desc = "Inspect variables and scopes" })

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

      -- Keep terminal transparency while preserving each theme's foregrounds and styles.
      local transparent_groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "FloatBorder",
        "SignColumn",
        "EndOfBuffer",
        "NormalSB",
        "MsgArea",
        "MsgSeparator",
        "FloatTitle",
        "FloatFooter",
        "SnacksDashboardNormal",
        "SnacksPicker",
        "SnacksPickerNormal",
        "SnacksPickerBorder",
        "SnacksPickerTitle",
        "SnacksPickerFooter",
      }

      local function apply_transparency()
        for _, group in ipairs(transparent_groups) do
          local ok, highlights = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
          if ok then
            highlights.bg = "NONE"
            vim.api.nvim_set_hl(0, group, highlights)
          end
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Keep terminal background transparent across colorschemes",
        callback = apply_transparency,
      })
      apply_transparency()

      local theme_state = vim.fn.stdpath("state") .. "/nixvim-colorscheme"
      local uv = vim.uv or vim.loop

      local function valid_theme_name(name)
        return type(name) == "string" and name:match("^[%w_.%-]+$") ~= nil
      end

      local function theme_available(name)
        if not valid_theme_name(name) then
          return false
        end
        return #vim.api.nvim_get_runtime_file("colors/" .. name .. ".lua", false) > 0
          or #vim.api.nvim_get_runtime_file("colors/" .. name .. ".vim", false) > 0
      end

      local function set_theme(name)
        if not theme_available(name) then
          return false, "colorscheme unavailable: " .. tostring(name)
        end
        local ok, err = pcall(function()
          vim.cmd.colorscheme(name)
        end)
        if not ok then
          return false, err
        end
        apply_transparency()
        return true
      end

      local function read_saved_theme()
        local fd = uv.fs_open(theme_state, "r", 0)
        if not fd then
          return nil
        end
        local stat = uv.fs_fstat(fd)
        local data = stat and stat.size <= 128 and uv.fs_read(fd, stat.size, 0) or nil
        uv.fs_close(fd)
        local name = data and data:match("^([%w_.%-]+)\n?$")
        return name and theme_available(name) and name or nil
      end

      local function save_theme(name)
        local state_dir = vim.fn.fnamemodify(theme_state, ":h")
        if vim.fn.mkdir(state_dir, "p", 448) == 0 and vim.fn.isdirectory(state_dir) == 0 then
          return false, "cannot create state directory: " .. state_dir
        end
        local temp = theme_state .. ".tmp." .. uv.os_getpid() .. "." .. uv.hrtime()
        local fd, err = uv.fs_open(temp, "wx", 384)
        if not fd then
          return false, err
        end
        local data = name .. "\n"
        local written, write_err = uv.fs_write(fd, data, 0)
        local ok = written == #data
        if not ok and not write_err then
          write_err = "short state write"
        end
        if ok and uv.fs_fsync then
          ok, write_err = uv.fs_fsync(fd)
        end
        uv.fs_close(fd)
        if not ok then
          uv.fs_unlink(temp)
          return false, write_err
        end
        local renamed, rename_err = uv.fs_rename(temp, theme_state)
        if not renamed then
          uv.fs_unlink(temp)
          return false, rename_err
        end
        return true
      end

      vim.api.nvim_create_user_command("NixvimThemePicker", function()
        local previous = vim.g.colors_name or "oxocarbon"
        Snacks.picker.colorschemes({
          confirm = function(picker, item)
            picker:close()
            if not item then
              return
            end
            picker.preview.state.colorscheme = nil
            vim.schedule(function()
              local applied, apply_err = set_theme(item.text)
              if not applied then
                set_theme(previous)
                vim.notify("Theme not applied: " .. tostring(apply_err), vim.log.levels.ERROR)
                return
              end
              local saved, save_err = save_theme(item.text)
              if saved then
                vim.notify("Theme selected: " .. item.text, vim.log.levels.INFO)
              else
                vim.notify("Theme applied, but state save failed: " .. tostring(save_err), vim.log.levels.ERROR)
              end
            end)
          end,
        })
      end, { desc = "Preview and select Neovim colorscheme" })

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        desc = "Restore saved colorscheme after plugins load",
        callback = function()
          local saved = read_saved_theme()
          local ok = set_theme(saved or "oxocarbon")
          if not ok and saved then
            set_theme("oxocarbon")
          end
        end,
      })

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

      -- Session persistence safety: exclude temporary paths and special panel buffers.
      local cwd = vim.fn.getcwd()
      if cwd:match("^/tmp") or cwd:match("^/var/tmp") then
        pcall(function()
          require("persistence").stop()
        end)
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        desc = "Close UI and special buffers before saving session",
        callback = function()
          pcall(function()
            local ok_dapui, dapui = pcall(require, "dapui")
            if ok_dapui then
              dapui.close()
            end
            local ok_trouble, trouble = pcall(require, "trouble")
            if ok_trouble and trouble.is_open() then
              trouble.close()
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        desc = "Restore highlights after loading session",
        callback = function()
          apply_transparency()
        end,
      })

      -- User commands for session persistence.
      vim.api.nvim_create_user_command("SessionRestore", function()
        require("persistence").load()
      end, { desc = "Restore session for current directory" })

      vim.api.nvim_create_user_command("SessionRestoreLast", function()
        require("persistence").load({ last = true })
      end, { desc = "Restore last session" })

      vim.api.nvim_create_user_command("SessionDelete", function()
        local persistence = require("persistence")
        local current_file = persistence.current()
        if vim.fn.filereadable(current_file) ~= 0 then
          vim.fn.delete(current_file)
        end
        local branch_file = persistence.current({ branch = false })
        if vim.fn.filereadable(branch_file) ~= 0 then
          vim.fn.delete(branch_file)
        end
        persistence.stop()
        vim.notify("Session deleted for current directory", vim.log.levels.INFO)
      end, { desc = "Delete session for current directory" })

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
        key = "<leader>co";
        action = "<cmd>botright copen 8<CR>";
        options.desc = "Open quickfix list";
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
      {
        mode = "n";
        key = "<leader>sd";
        action = "<cmd>lua Snacks.dashboard()<CR>";
        options.desc = "Open dashboard";
      }
      {
        mode = "n";
        key = "<leader>qs";
        action = "<cmd>lua require('persistence').load()<CR>";
        options.desc = "Restore session for current directory";
      }
      {
        mode = "n";
        key = "<leader>ql";
        action = "<cmd>lua require('persistence').load({ last = true })<CR>";
        options.desc = "Restore last session";
      }
      {
        mode = "n";
        key = "<leader>qd";
        action = "<cmd>SessionDelete<CR>";
        options.desc = "Delete session for current directory";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "<leader>j";
        action = "<cmd>lua require('flash').jump()<CR>";
        options.desc = "Flash jump";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "<leader>J";
        action = "<cmd>lua require('flash').treesitter()<CR>";
        options.desc = "Flash treesitter";
      }
      {
        mode = "o";
        key = "r";
        action = "<cmd>lua require('flash').remote()<CR>";
        options.desc = "Remote flash";
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
