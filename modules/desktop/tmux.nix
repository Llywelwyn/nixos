{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    programs.tmux = {
      enable = true;
      sensibleOnTop = false;
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.tmux-fzf;
          extraConfig = ''
            TMUX_FZF_LAUNCH_KEY="v"                           # <prefix>v to open tmux-fzf menu
            TMUX_FZF_ORDER="session|window|pane|command"      # hides some unused options from tmux-fzf menu
          '';
        }
      ];
      extraConfig = ''
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?\.?(view|n?vim?x?)(-wrapped)?(diff)?$'"
        bind-key   -n  M-Left    if-shell "$is_vim" 'send-keys M-Left'    'select-pane -L'
        bind-key   -n  M-Right   if-shell "$is_vim" 'send-keys M-Right'   'select-pane -R'
        bind-key   -n  M-Up      if-shell "$is_vim" 'send-keys M-Up'      'select-pane -U'
        bind-key   -n  M-Down    if-shell "$is_vim" 'send-keys M-Down'    'select-pane -D'
        bind-key   -n  M-C-Left  if-shell "$is_vim" 'send-keys M-C-Left'  'resize-pane -L 5'
        bind-key   -n  M-C-Right if-shell "$is_vim" 'send-keys M-C-Right' 'resize-pane -R 5'
        bind-key   -n  M-C-Up    if-shell "$is_vim" 'send-keys M-C-Up'    'resize-pane -U 3'
        bind-key   -n  M-C-Down  if-shell "$is_vim" 'send-keys M-C-Down'  'resize-pane -D 3'
        bind-key   -n  M-S-Left  if-shell "$is_vim" 'send-keys M-S-Left'  'swap-pane   -s "{left-of}"'
        bind-key   -n  M-S-Right if-shell "$is_vim" 'send-keys M-S-Right' 'swap-pane   -s "{right-of}"'
        bind-key   -n  M-S-Up    if-shell "$is_vim" 'send-keys M-S-Up'    'swap-pane   -s "{up-of}"'
        bind-key   -n  M-S-Down  if-shell "$is_vim" 'send-keys M-S-Down'  'swap-pane   -s "{down-of}"'

        unbind        C-b                                     # unbind default prefix
        bind-key      `                    send-prefix        # bind backtick as prefix
        bind-key      -                    split-window       # split
        bind-key      \;                   split-window -h    # horizontal split
        bind-key       r                   source-file        ~/.config/tmux/tmux.conf \; display-message "reloaded tmux config"
        bind-key       c                   command-prompt  -p "window name:" "new-window; rename-window '%%'"
        bind-key       C-f                 display-popup   -E -w 80% -h 80% "tmux-sessionizer"
        bind-key       l                   if-shell "git -C '#{pane_current_path}' rev-parse --git-dir >/dev/null 2>&1" \
                                             "display-popup -E -w 80% -h 80% -d '#{pane_current_path}' 'lazygit'" \
                                             "display-message 'Not a git repository'"
        bind-key       C-q                 command-prompt  -p find-session 'switch-client -t %%'
        bind-key       Left                previous-window    # window back
        bind-key       Right               next-window        # window forward
        bind-key       Up                  switch-client   -p # session back
        bind-key       Down                switch-client   -n # session forward
        bind-key   -n  M-z                 resize-pane     -Z # pane zoom
        bind-key   -n  M-w                 confirm-before  -p "are you sure you want to kill #P?" kill-pane

        set-option -g  prefix              `                  # "
        set-option -g  default-terminal    "tmux-256color"    # 256-colors
        set-option -s  extended-keys       on
        set-option -as terminal-features   "xterm*:extkeys"
        set-option -s  escape-time         0                  # vi-mode switch delay
        set-option -g  history-limit       50000              # scrollback buffer size
        set-option -g  display-time        6000               # tmux msg display duration
        set-option -g  status-interval     5                  # status-left/right refresh rate
        set-option -g  focus-events        on                 # allow tmux to react to terminal focus events
        set-option -g  exit-empty          off                # don't exit tmux when the last pane is closed
        set-option -g  exit-unattached     off                # don't exit tmux when all clients detach
        set-option -g  detach-on-destroy   off                # don't detach clients when a session is destroyed
        set-option -g  renumber-windows    on                 # renumber windows when one is closed
        set-option -g  base-index          1                  # start window numbering at 1
        set-window -g  pane-base-index     1                  # start pane numbering at 1
        set-option -g  allow-rename        off                # don't rename windows automatically
        set-option -g  mouse               on                 # mouse control
        set-option -g  status-style        bg=default         # status styling
        set-option -g  status-left-length  40                 # max allowed length
        set-option -g  status-justify      absolute-centre    # windows alignment
        set-option -g  status-left         "#{?client_prefix,#[bg=white]#[fg=black]#H @ #S.COMMAND,#[bg=default]#H @ #S}"
        set-option -g  status-right        "#{?window_bigger,[#{window_offset_x}#,#{window_offset_y}] ,}\"#{=21:pane_title}\""
      '';
    };

    home.packages = [
      (pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ./_scripts/tmux-sessionizer))
      (pkgs.writeShellScriptBin "shrink" (builtins.readFile ./_scripts/shrink))
      (pkgs.writeShellScriptBin "localhost" (builtins.readFile ./_scripts/localhost))
    ];

    xdg.configFile."tmux-sessionizer/sources.conf".text = ''
      ~/projects|1|1
      ~/.config|0|1
    '';
  };
}
