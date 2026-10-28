{ pkgs, ... }:

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
