{ config, pkgs, ... }:

{
  # Snacks: dashboard, picker, Explorer and trash history.
  programs.nixvim.plugins = {
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
  };
}
