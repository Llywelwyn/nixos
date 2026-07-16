{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    programs.claude-code = {
      enable = true;
      settings = {
        tui = "fullscreen";
        theme = "auto";
        model = "claude-fable-5[1m]";
        includeCoAuthoredBy = false;
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };
        statusLine = {
          type = "command";
          command = ''
            input=$(cat); \
            cwd=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.cwd'); \
            short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|"); \
            model=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name'); \
            branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null); \
            if [ -n "$branch" ]; then \
              dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1); \
              [ -n "$dirty" ] && branch="$branch*"; \
              git_part=" ($branch)"; \
            else \
              git_part=""; \
            fi; \
            ctx=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.context_window.remaining_percentage // empty'); \
            fh=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.five_hour.used_percentage // empty'); \
            fhr=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.five_hour.resets_at // empty'); \
            wk=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.seven_day.used_percentage // empty'); \
            wkr=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.seven_day.resets_at // empty'); \
            now=$(date +%s); \
            fmt() { \
              if [ "$1" -ge 86400 ]; then echo "$(( $1 / 86400 ))d"; \
              elif [ "$1" -ge 3600 ]; then echo "$(( $1 / 3600 ))h$(( ($1 % 3600) / 60 ))m"; \
              else echo "$(( $1 / 60 ))m"; fi; \
            }; \
            usage=""; \
            [ -n "$ctx" ] && usage="$usage · $(printf '%.0f' "$ctx")%"; \
            if [ -n "$fh" ]; then \
              seg="$(printf '%.0f' "$fh")%"; \
              [ -n "$fhr" ] && [ $(( fhr - now )) -gt 0 ] && seg="$seg ($(fmt $(( fhr - now ))))"; \
              usage="$usage · $seg"; \
            fi; \
            if [ -n "$wk" ]; then \
              seg="$(printf '%.0f' "$wk")%"; \
              [ -n "$wkr" ] && [ $(( wkr - now )) -gt 0 ] && seg="$seg ($(fmt $(( wkr - now ))))"; \
              usage="$usage · $seg"; \
            fi; \
            echo "$short_cwd$git_part  $model$usage"
          '';
        };
      };
    };
  };
}
