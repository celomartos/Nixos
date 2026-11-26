{ pkgs, ... }:

{
  programs.nixvim = {
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

  };
}
