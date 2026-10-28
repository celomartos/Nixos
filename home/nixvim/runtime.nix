{ ... }:

{
  programs.nixvim = {
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
  };
}
