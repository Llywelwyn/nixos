{
  flake.modules.homeManager.desktop.programs.nixvim.keymaps = [
    {
      mode = [ "n" "v" ];
      key = "<C-w>s";
      action = "<nop>";
    }
    {
      mode = [ "n" "v" ];
      key = "<C-w>v";
      action = "<nop>";
    }
    {
      mode = "n";
      key = "<Leader>;";
      action = "<Cmd>vsplit<CR>";
      options = { noremap = true; desc = "vsplit"; };
    }
    {
      mode = "n";
      key = "<Leader>-";
      action = "<Cmd>split<CR>";
      options = { noremap = true; desc = "hsplit"; };
    }
    {
      mode = "n";
      key = "<Leader>ca";
      action = "<Cmd>lua vim.lsp.buf.code_action()<CR>";
      options = { noremap = true; desc = "lsp code action"; };
    }
    {
      mode = "n";
      key = "<Leader>ci";
      action = "<Cmd>lua vim.lsp.buf.implementation()<CR>";
      options = { noremap = true; desc = "lsp find implementation"; };
    }
    {
      mode = "n";
      key = "<Leader>cr";
      action = "<Cmd>lua vim.lsp.buf.references()<CR>";
      options = { noremap = true; desc = "lsp find references"; };
    }
    {
      mode = "n";
      key = "<Leader>cR";
      action = "<Cmd>lua vim.lsp.buf.rename()<CR>";
      options = { noremap = true; desc = "lsp rename"; };
    }
    {
      mode = "n";
      key = ">";
      action.__raw = ''function() for _ = 1, vim.v.count1 do vim.cmd("normal! >>") end end'';
      options = { noremap = true; desc = "indent"; };
    }
    {
      mode = "n";
      key = "<";
      action.__raw = ''function() for _ = 1, vim.v.count1 do vim.cmd("normal! <<") end end'';
      options = { noremap = true; desc = "dedent"; };
    }
    {
      mode = "x";
      key = ">";
      action = ">gv";
      options = { noremap = true; desc = "indent and reselect"; };
    }
    {
      mode = "x";
      key = "<";
      action = "<gv";
      options = { noremap = true; desc = "dedent and reselect"; };
    }
  ];
}
