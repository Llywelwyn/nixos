: "${SERVICES:?must be set}"
: "${OUTPUT_PATH:?must be set}"
: "${RETENTION_DAYS:?must be set}"
: "${DISPLAY_DAYS:?must be set}"

state_dir=$(dirname "$OUTPUT_PATH")
mkdir -p "$state_dir"

now=$(date -u +%s)
retention_cutoff=$(( now - RETENTION_DAYS * 86400 ))

# Probe each service and rotate its log.
while IFS= read -r line; do
  [ -z "$line" ] && continue
  name=${line%% *}
  url=${line#* }
  log="$state_dir/$name.log"

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
done <<< "$SERVICES"

# Render. bucket_size and cell_count are parameters so we can add
# hour/minute granularity rows later without restructuring the awk.
render_row() {
  local log_file="$1"
  local now_arg="$2"
  local bucket_size="$3"
  local cells="$4"

  if [ ! -s "$log_file" ]; then
    local pad
    pad=$(printf '%*s' "$cells" '' | tr ' ' '?')
    printf '%s 0.0 unknown\n' "$pad"
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
        if (u + d == 0)      bar = bar "?"
        else if (d == 0)     bar = bar "#"
        else if (u == 0)     bar = bar "_"
        else                 bar = bar "."
        total_up += u; total_all += u + d
      }
      pct = (total_all == 0) ? 0 : (100 * total_up / total_all)
      state = (last_ok == 1) ? "up" : (last_ok == 0) ? "down" : "unknown"
      printf "%s %.1f %s\n", bar, pct, state
    }' "$log_file"
}

day_bucket=86400

tmp="$OUTPUT_PATH.tmp"
{
  printf '# updated %s\n\n' "$(date -u -d "@$now" '+%Y-%m-%d %H:%M:%S UTC')"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=${line%% *}
    log="$state_dir/$name.log"
    read -r bar pct state < <(render_row "$log" "$now" "$day_bucket" "$DISPLAY_DAYS")
    printf '%-20s %s %-7s %5s%%\n' "$name" "$bar" "$state" "$pct"
  done <<< "$SERVICES"

  printf '\nlegend: # up   . degraded   _ down   ? no data\n'
} > "$tmp"

mv "$tmp" "$OUTPUT_PATH"
