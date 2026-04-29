: "${CONFIG_PATH:?must be set}"
: "${INTRO_PATH:?must be set}"
: "${OUTPUT_PATH:?must be set}"
: "${RETENTION_DAYS:?must be set}"
: "${DISPLAY_DAYS:?must be set}"
: "${DISPLAY_HOURS:?must be set}"

state_dir=$(dirname "$OUTPUT_PATH")
mkdir -p "$state_dir"

now=$(date -u +%s)
retention_cutoff=$(( now - RETENTION_DAYS * 86400 ))

# Parse categories into parallel arrays indexed by category number.
cat_intervals=()
cat_hideurls=()
cat_descriptions=()
while IFS=$'\t' read -r tag idx interval hideurls desc; do
  if [ "$tag" = "CAT" ]; then
    cat_intervals[idx]=$interval
    cat_hideurls[idx]=$hideurls
    cat_descriptions[idx]=$desc
  fi
done < "$CONFIG_PATH"

# Compute name column width across all services.
max_name_len=0
while IFS=$'\t' read -r tag _ name _; do
  [ "$tag" != "SVC" ] && continue
  (( ${#name} > max_name_len )) && max_name_len=${#name}
done < "$CONFIG_PATH"
name_col=$(( max_name_len + 2 ))

# Probe phase: gate per-service by the owning category's intervalSeconds.
while IFS=$'\t' read -r tag cat_idx name url; do
  [ "$tag" != "SVC" ] && continue
  interval=${cat_intervals[cat_idx]}
  log="$state_dir/$name.log"

  if [ -s "$log" ]; then
    last_ts=$(tail -n 1 "$log" | awk '{print $1}')
    age=$(( now - last_ts ))
    (( age < interval )) && continue
  fi

  code=$(curl -fsS --max-time 10 -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)
  if [ -z "$code" ] || [ "$code" = "000" ]; then
    code="000"
    up=0
  elif [ "${code:0:1}" = "2" ] || [ "${code:0:1}" = "3" ]; then
    up=1
  else
    up=0
  fi
  printf '%s %s %s\n' "$now" "$up" "$code" >> "$log"

  awk -v cutoff="$retention_cutoff" '$1 >= cutoff' "$log" > "$log.tmp"
  mv "$log.tmp" "$log"
done < "$CONFIG_PATH"

# Render helpers.
render_row() {
  local log_file="$1" now_arg="$2" bucket_size="$3" cells="$4"

  if [ ! -s "$log_file" ]; then
    local pad
    pad=$(printf '%*s' "$cells" '' | tr ' ' '.')
    printf '%s 0.000 unknown\n' "$pad"
    return
  fi

  awk -v now="$now_arg" -v bucket="$bucket_size" -v cells="$cells" '
    BEGIN {
      bucket_origin = int(now / bucket) * bucket
      window_start = bucket_origin - (cells - 1) * bucket
      window_end = bucket_origin + bucket
      last_ok = -1
    }
    {
      ts = $1; ok = $2
      if (ts >= window_start && ts < window_end) {
        idx = int((ts - window_start) / bucket)
        if (idx >= 0 && idx < cells) {
          if (ok == 1) up[idx]++; else down[idx]++
        }
      }
      last_ok = ok
    }
    END {
      bar = ""; total_up = 0; total_all = 0
      for (i = 0; i < cells; i++) {
        u = (i in up) ? up[i] : 0
        d = (i in down) ? down[i] : 0
        if (u + d == 0)      bar = bar "."
        else if (d == 0)     bar = bar "="
        else if (u == 0)     bar = bar "_"
        else                 bar = bar "-"
        total_up += u; total_all += u + d
      }
      pct = (total_all == 0) ? 0 : (100 * total_up / total_all)
      state = (last_ok == 1) ? "up" : (last_ok == 0) ? "down" : "unknown"
      printf "%s %.3f %s\n", bar, pct, state
    }' "$log_file"
}

scale_bar() {
  local cells="$1" left="$2" right="$3"
  local fill=$(( cells - ${#left} - ${#right} ))
  if (( fill < 1 )); then
    printf '%*s' "$cells" '' | tr ' ' '-'
  else
    printf '%s%*s%s' "$left" "$fill" '' "$right"
  fi
}

center() {
  local width="$1" text="$2"
  local fill=$(( width - ${#text} ))
  if (( fill <= 0 )); then
    printf '%s' "$text"
  else
    local left_pad=$(( fill / 2 )) right_pad
    right_pad=$(( fill - left_pad ))
    printf '%*s%s%*s' "$left_pad" '' "$text" "$right_pad" ''
  fi
}

human_interval() {
  local s="$1"
  if   (( s < 60 ));   then printf '%d seconds' "$s"
  elif (( s == 60 ));  then printf '1 minute'
  elif (( s < 3600 )); then printf '%d minutes' "$(( s / 60 ))"
  elif (( s == 3600 )); then printf '1 hour'
  else                       printf '%d hours' "$(( s / 3600 ))"
  fi
}

day_bar_cells=30
day_bucket=$(( DISPLAY_DAYS * 86400 / day_bar_cells ))
days_per_cell=$(( DISPLAY_DAYS / day_bar_cells ))
if (( days_per_cell == 1 )); then
  day_unit="1 day"
else
  day_unit="$days_per_cell days"
fi

hour_bar_cells="$DISPLAY_HOURS"
hour_bucket=3600

day_scale=$(scale_bar "$day_bar_cells" "<-${DISPLAY_DAYS}d" "now->")
hour_scale=$(scale_bar "$hour_bar_cells" "<-${DISPLAY_HOURS}h" "now->")
day_label=$(center "$day_bar_cells" "1 cell = $day_unit")
hour_label=$(center "$hour_bar_cells" "1 cell = 1 hour")

tmp="$OUTPUT_PATH.tmp"
{
  printf '# updated %s\n' "$(date -u -d "@$now" '+%Y-%m-%d %H:%M:%S UTC')"

  if [ -s "$INTRO_PATH" ]; then
    intro_content=$(cat "$INTRO_PATH")
    printf '\n%s\n' "$intro_content"
  fi

  n_cats=${#cat_intervals[@]}
  for (( cat_idx = 0; cat_idx < n_cats; cat_idx++ )); do
    desc=${cat_descriptions[cat_idx]}
    interval=${cat_intervals[cat_idx]}

    printf '\n'
    if [ -n "$desc" ]; then
      printf '%s (probed every %s)\n\n' "$desc" "$(human_interval "$interval")"
    fi

    printf "%-${name_col}s%s  %s\n" '' "$day_scale" "$hour_scale"

    while IFS=$'\t' read -r tag c_idx name url; do
      [ "$tag" != "SVC" ] && continue
      [ "$c_idx" != "$cat_idx" ] && continue
      log="$state_dir/$name.log"
      read -r day_bar day_pct _ < <(render_row "$log" "$now" "$day_bucket" "$day_bar_cells")
      read -r hour_bar _ state < <(render_row "$log" "$now" "$hour_bucket" "$hour_bar_cells")
      if [ "${cat_hideurls[cat_idx]}" = "1" ]; then
        printf "%-${name_col}s%s  %s  %s  %s%%\n" \
          "$name" "$day_bar" "$hour_bar" "$state" "$day_pct"
      else
        printf "%-${name_col}s%s  %s  %s  %s%%  %s\n" \
          "$name" "$day_bar" "$hour_bar" "$state" "$day_pct" "$url"
      fi
    done < "$CONFIG_PATH"

    printf "%-${name_col}s%s  %s\n" '' "$day_label" "$hour_label"
  done

  printf '\nlegend: = up   - degraded   _ down   . no data\n'
  printf '\nBy: l@ily.rs\n'
} > "$tmp"

mv "$tmp" "$OUTPUT_PATH"
