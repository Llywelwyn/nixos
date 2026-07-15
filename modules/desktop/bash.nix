{
  flake.modules.homeManager.desktop = { lib, ... }: {
    programs = {
      bash = {
        enable = true;
        historySize = 32768;
        historyFileSize = 32768;
        historyControl = [ "ignoredups" "ignorespace" ];

        shellAliases = {
          ls = "eza -lh --group-directories-first --icons=auto";
          lsa = "ls -a";
          lt = "eza --tree --level=2 --long --icons --git";
          lta = "lt -a";

          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
        };

        # order 3000: attach last, after zoxide/fzf init (zoxide uses mkOrder 2000)
        initExtra = lib.mkOrder 3000 ''
          if [[ -z "$TMUX" && "$TERM" != "dumb" ]] && command -v tmux >/dev/null; then
            tmux new-session -A -s default
          fi
        '';
      };

      fzf.enable = true;

      readline = {
        enable = true;
        variables = {
          completion-ignore-case = true;
          completion-prefix-display-length = 2;
          show-all-if-ambiguous = true;
          show-all-if-unmodified = true;
          mark-symlinked-directories = true;
          match-hidden-files = false;
          page-completions = false;
          completion-query-items = 200;
          visible-stats = true;
          skip-completed-text = true;
          colored-stats = true;
        };
        bindings = {
          "\\e[A" = "history-search-backward";
          "\\e[B" = "history-search-forward";
          "\\e[C" = "forward-char";
          "\\e[D" = "backward-char";
        };
      };
    };

    home.sessionVariables.BAT_THEME = "ansi";
  };
}
