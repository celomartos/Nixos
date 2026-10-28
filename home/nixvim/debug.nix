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
  };
}
