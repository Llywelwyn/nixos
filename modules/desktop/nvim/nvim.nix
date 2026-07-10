{ inputs, ... }:
{
  flake.modules.homeManager.desktop = {
    imports = [ inputs.nixvim.homeModules.nixvim ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      nixpkgs.source = inputs.nixpkgs;

      globals = {
        mapleader = " ";
        maplocalleader = "\\";
      };

      opts = {
        mouse = "";
        mousescroll = "ver:25,hor:6";
        switchbuf = "usetab";
        undofile = true;
        breakindent = true;
        breakindentopt = "list:-1";
        colorcolumn = "+1";
        cursorline = true;
        linebreak = true;
        list = true;
        number = true;
        relativenumber = true;
        pumheight = 10;
        ruler = false;
        signcolumn = "yes";
        splitbelow = true;
        splitright = true;
        winborder = "single";
        wrap = false;
        cursorlineopt = "screenline,number";
        foldlevel = 10;
        foldmethod = "indent";
        foldnestmax = 10;
        foldtext = "";
        autoindent = true;
        expandtab = true;
        ignorecase = true;
        incsearch = true;
        infercase = true;
        smartcase = true;
        smartindent = true;
        virtualedit = "block";
        iskeyword = "@,48-57,_,192-255,-";
        tabstop = 2;
        shiftwidth = 2;
        statusline = "%r%m%=";
        formatexpr = "v:lua.require'conform'.formatexpr()";
      };

      diagnostic.settings.virtual_text = true;

      autoGroups.highlight-yank.clear = true;
      autoCmd = [
        {
          event = "TextYankPost";
          group = "highlight-yank";
          desc = "Highlight when yanking text";
          callback.__raw = "function() vim.highlight.on_yank() end";
        }
      ];

      extraFiles."colors/mono.lua".source = ./_colors/mono.lua;
    };
  };
}
