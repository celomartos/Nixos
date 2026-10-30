{ config, pkgs, ... }:

{
  # Debugger and debugger UI.
  programs.nixvim.plugins = {
      dap =
        let
          launchConfiguration = {
            type = "codelldb";
            request = "launch";
            name = "Launch executable";
            program.__raw = ''
              function()
                local dap = require("dap")
                if vim.bo.modified then
                  vim.notify("Save the file before debugging it", vim.log.levels.WARN)
                  return dap.ABORT
                end

                local function choose_executable(default_path)
                  local selected = vim.fn.input("Path to executable: ", default_path, "file")
                  if selected == "" then
                    return dap.ABORT
                  end

                  local executable = vim.fn.fnamemodify(vim.fn.expand(vim.fn.trim(selected)), ":p")
                  if vim.fn.executable(executable) ~= 1 then
                    vim.notify("Not an executable file: " .. executable, vim.log.levels.ERROR)
                    return dap.ABORT
                  end
                  return executable
                end

                if vim.bo.filetype == "rust" then
                  local root = vim.fs.root(0, "Cargo.toml")
                  if root then
                    if vim.fn.executable("cargo") ~= 1 then
                      vim.notify("Cargo executable not found", vim.log.levels.ERROR)
                      return dap.ABORT
                    end

                    local manifest = vim.fs.joinpath(root, "Cargo.toml")
                    local ok_metadata, metadata_result = pcall(function()
                      return vim.system({
                        "cargo",
                        "metadata",
                        "--no-deps",
                        "--format-version",
                        "1",
                        "--manifest-path",
                        manifest,
                      }, { cwd = root, text = true }):wait()
                    end)
                    if not ok_metadata or metadata_result.code ~= 0 then
                      local detail = ok_metadata and (metadata_result.stderr ~= "" and metadata_result.stderr or metadata_result.stdout)
                        or metadata_result
                      vim.notify("Cargo metadata failed: " .. vim.fn.trim(detail or ""), vim.log.levels.ERROR)
                      return dap.ABORT
                    end

                    local ok_decode, metadata = pcall(vim.json.decode, metadata_result.stdout)
                    if not ok_decode then
                      vim.notify("Could not read Cargo project metadata: " .. tostring(metadata), vim.log.levels.ERROR)
                      return dap.ABORT
                    end

                    local function canonical(path)
                      local uv = vim.uv or vim.loop
                      return uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p")
                    end

                    local root_manifest = canonical(manifest)
                    local root_package
                    local packages_by_id = {}
                    for _, package in ipairs(metadata.packages or {}) do
                      packages_by_id[package.id] = package
                      if canonical(package.manifest_path) == root_manifest then
                        root_package = package
                      end
                    end

                    local packages = {}
                    if root_package then
                      packages = { root_package }
                    else
                      local member_ids = metadata.workspace_default_members
                      if type(member_ids) ~= "table" or #member_ids == 0 then
                        member_ids = metadata.workspace_members or {}
                      end
                      for _, id in ipairs(member_ids) do
                        if packages_by_id[id] then
                          table.insert(packages, packages_by_id[id])
                        end
                      end
                    end

                    local binaries = {}
                    for _, package in ipairs(packages) do
                      for _, target in ipairs(package.targets or {}) do
                        if vim.tbl_contains(target.kind or {}, "bin") then
                          table.insert(binaries, { package = package, target = target })
                        end
                      end
                    end

                    local current_file = canonical(vim.fn.expand("%:p"))
                    local selected_binary
                    for _, binary in ipairs(binaries) do
                      if canonical(binary.target.src_path) == current_file then
                        selected_binary = binary
                        break
                      end
                    end

                    if not selected_binary and #binaries == 1 then
                      selected_binary = binaries[1]
                    elseif not selected_binary and #binaries > 1 then
                      local choices = { "Select Cargo binary:" }
                      for _, binary in ipairs(binaries) do
                        table.insert(choices, binary.package.name .. "/" .. binary.target.name)
                      end
                      local choice = vim.fn.inputlist(choices)
                      selected_binary = binaries[choice]
                    end

                    if not selected_binary then
                      vim.notify("No Cargo binary selected for debugging", vim.log.levels.WARN)
                      return dap.ABORT
                    end

                    local build_command = {
                      "cargo",
                      "build",
                      "--message-format=json-render-diagnostics",
                      "--manifest-path",
                      selected_binary.package.manifest_path,
                      "--bin",
                      selected_binary.target.name,
                    }
                    local ok_build, build_result = pcall(function()
                      return vim.system(build_command, { cwd = root, text = true }):wait()
                    end)
                    if not ok_build then
                      vim.notify("Could not run Cargo build: " .. tostring(build_result), vim.log.levels.ERROR)
                      return dap.ABORT
                    end

                    local executable
                    local diagnostics = {}
                    for _, line in ipairs(vim.split(build_result.stdout or "", "\n", { trimempty = true })) do
                      local ok_event, event = pcall(vim.json.decode, line)
                      if ok_event and event.reason == "compiler-artifact"
                        and event.package_id == selected_binary.package.id
                        and event.target
                        and event.target.name == selected_binary.target.name
                        and vim.tbl_contains(event.target.kind or {}, "bin") then
                        executable = event.executable or executable
                      elseif ok_event and event.reason == "compiler-message"
                        and event.message and event.message.rendered then
                        table.insert(diagnostics, event.message.rendered)
                      end
                    end

                    if build_result.code ~= 0 then
                      local detail = #diagnostics > 0 and table.concat(diagnostics, "\n")
                        or vim.fn.trim(build_result.stderr ~= "" and build_result.stderr or build_result.stdout or "")
                      vim.notify("Cargo build failed:\n" .. detail, vim.log.levels.ERROR)
                      return dap.ABORT
                    end

                    if not executable or vim.fn.executable(executable) ~= 1 then
                      vim.notify("Cargo did not produce an executable for " .. selected_binary.target.name, vim.log.levels.ERROR)
                      return dap.ABORT
                    end
                    return executable
                  end

                  return choose_executable(vim.fn.getcwd() .. "/")
                end

                return choose_executable(vim.fn.getcwd() .. "/")
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
  };
}
