{ ... }:

{
  programs.nixvim = {
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
  };
}
