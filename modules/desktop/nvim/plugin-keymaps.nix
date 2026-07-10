{
  flake.modules.homeManager.desktop.programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<M-Left>";
      action.__raw = ''function() require("tmux").move_left() end'';
    }
    {
      mode = "n";
      key = "<M-Right>";
      action.__raw = ''function() require("tmux").move_right() end'';
    }
    {
      mode = "n";
      key = "<M-Up>";
      action.__raw = ''function() require("tmux").move_top() end'';
    }
    {
      mode = "n";
      key = "<M-Down>";
      action.__raw = ''function() require("tmux").move_bottom() end'';
    }
    {
      mode = "n";
      key = "<M-C-Left>";
      action.__raw = ''function() require("tmux").resize_left() end'';
    }
    {
      mode = "n";
      key = "<M-C-Right>";
      action.__raw = ''function() require("tmux").resize_right() end'';
    }
    {
      mode = "n";
      key = "<M-C-Up>";
      action.__raw = ''function() require("tmux").resize_top() end'';
    }
    {
      mode = "n";
      key = "<M-C-Down>";
      action.__raw = ''function() require("tmux").resize_bottom() end'';
    }
    {
      mode = "n";
      key = "<M-S-Left>";
      action.__raw = ''function() require("tmux").swap_left() end'';
    }
    {
      mode = "n";
      key = "<M-S-Right>";
      action.__raw = ''function() require("tmux").swap_right() end'';
    }
    {
      mode = "n";
      key = "<M-S-Up>";
      action.__raw = ''function() require("tmux").swap_top() end'';
    }
    {
      mode = "n";
      key = "<M-S-Down>";
      action.__raw = ''function() require("tmux").swap_bottom() end'';
    }

    {
      mode = "n";
      key = "<leader>f\"";
      action = "<cmd>FzfLua registers<CR>";
      options.desc = "fzf registers";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>FzfLua buffers<CR>";
      options.desc = "fzf buffers";
    }
    {
      mode = "n";
      key = "<leader>fc";
      action = "<cmd>FzfLua commands<CR>";
      options.desc = "fzf commands";
    }
    {
      mode = "n";
      key = "<leader>fe";
      action = "<cmd>FzfLua changes<CR>";
      options.desc = "fzf edits";
    }
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>FzfLua files<CR>";
      options.desc = "fzf files";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>FzfLua live_grep<CR>";
      options.desc = "fzf grep";
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>FzfLua command_history<CR>";
      options.desc = "fzf cmd history";
    }
    {
      mode = "n";
      key = "<leader>fk";
      action = "<cmd>FzfLua keymaps<CR>";
      options.desc = "fzf keymaps";
    }
    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>FzfLua oldfiles<CR>";
      options.desc = "fzf oldfiles";
    }
    {
      mode = "n";
      key = "<leader>fs";
      action = "<cmd>FzfLua<CR>";
      options.desc = "fzf something else";
    }

    {
      mode = "n";
      key = "<leader>?";
      action.__raw = ''function() require("which-key").show({ global = true }) end'';
      options.desc = "show local keymaps";
    }

    {
      mode = "n";
      key = "<leader>o";
      action = "<Cmd>Oil<CR>";
      options.desc = "oil";
    }

    {
      mode = "n";
      key = "<leader>gb";
      action.__raw = ''function() require("mini.git").show_at_cursor() end'';
      options.desc = "git blame current line";
    }
    {
      mode = "n";
      key = "<leader>g]";
      action.__raw = ''function() require("mini.diff").goto_hunk("next") end'';
      options.desc = "git next hunk";
    }
    {
      mode = "n";
      key = "<leader>g[";
      action.__raw = ''function() require("mini.diff").goto_hunk("prev") end'';
      options.desc = "git prev hunk";
    }
    {
      mode = "n";
      key = "<leader>gp";
      action.__raw = ''function() require("mini.diff").toggle_overlay() end'';
      options.desc = "git preview hunks";
    }

    {
      mode = "";
      key = "<leader>af";
      action.__raw = ''function() require("conform").format({ async = true }) end'';
      options.desc = "format buffer";
    }

    {
      mode = "n";
      key = "y";
      action = "<Plug>(YankyYank)";
      options.desc = "yank";
    }
    {
      mode = [ "n" "x" ];
      key = "p";
      action = "<Plug>(YankyPutAfter)";
      options.desc = "put after";
    }
    {
      mode = [ "n" "x" ];
      key = "P";
      action = "<Plug>(YankyPutBefore)";
      options.desc = "put before";
    }
    {
      mode = [ "n" "x" ];
      key = "[p";
      action = "<Plug>(YankyPutIndentBeforeLinewise)";
      options.desc = "put after line";
    }
    {
      mode = [ "n" "x" ];
      key = "]p";
      action = "<Plug>(YankyPutIndentAfterLinewise)";
      options.desc = "put before line";
    }
    {
      mode = "n";
      key = "<c-p>";
      action = "<Plug>(YankyPreviousEntry)";
      options.desc = "previous yank";
    }
    {
      mode = "n";
      key = "<c-n>";
      action = "<Plug>(YankyNextEntry)";
      options.desc = "next yank";
    }
    {
      mode = [ "n" "x" ];
      key = "<leader>fy";
      action = "<Cmd>YankyRingHistory<CR>";
      options.desc = "yank history";
    }
  ];
}
