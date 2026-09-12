return {
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,

    config = function()
      vim.cmd.colorscheme("moonfly")

      vim.cmd([[
        highlight Normal guibg=NONE
        highlight NormalNC guibg=NONE
        highlight SignColumn guibg=NONE
        highlight LineNr guibg=NONE
        highlight CursorLineNr guibg=NONE
        highlight EndOfBuffer guibg=NONE
      ]])
    end,
  },
}
