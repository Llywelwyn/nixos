{ config, pkgs, ... }:
let
  chatId = "8669496383";
  port = 8000;

  settings = {
    config.refresh_rate = "1s";

    server = {
      address = "127.0.0.1:${toString port}";
      url = "https://file.ily.rs";
      max_content_length = "50MB";
      upload_path = "/srv/rustypaste/upload";
      timeout = "30s";
      expose_version = false;
      expose_list = false;
      handle_spaces = "replace";
    };

    landing_page = {
      content_type = "text/plain; charset=utf-8";
      text = ''
        file.ily.rs

        Upload a file:
            curl -F 'file=@example.txt' https://file.ily.rs
        This returns the URL of the uploaded file.

        Uploads are public and kept indefinitely. The administrator may
        remove anything they do not want to host.
      '';
    };

    paste = {
      random_url = { type = "alphanumeric"; length = 4; };
      default_extension = "txt";
      mime_override = [
        { mime = "image/jpeg"; regex = "^.*\\.jpg$"; }
        { mime = "image/png"; regex = "^.*\\.png$"; }
        { mime = "image/svg+xml"; regex = "^.*\\.svg$"; }
        { mime = "video/webm"; regex = "^.*\\.webm$"; }
        { mime = "video/x-matroska"; regex = "^.*\\.mkv$"; }
        { mime = "application/octet-stream"; regex = "^.*\\.bin$"; }
        { mime = "text/plain"; regex = "^.*\\.(log|txt|diff|sh|rs|toml|nix)$"; }
      ];
      mime_blacklist = [
        "application/x-dosexec"
        "application/x-executable"
        "application/java-archive"
        "application/java-vm"
      ];
      duplicate_files = false;
      delete_expired_files = { enabled = true; interval = "1h"; };
    };
  };

  configFile = (pkgs.formats.toml { }).generate "rustypaste-config.toml" settings;

  notifyScript = pkgs.writeShellScript "rustypaste-notify" ''
    set -u
    token=$(tr -d '\n' < ${config.sops.secrets.rustypaste-telegram-token.path})

    send() { # $1: text, $2: "preview" to keep the link preview
      preview=true
      [ "''${2:-}" = "preview" ] && preview=false
      ${pkgs.curl}/bin/curl -fsS --max-time 10 \
        -X POST "https://api.telegram.org/bot$token/sendMessage" \
        --data-urlencode "chat_id=${chatId}" \
        --data-urlencode "text=$1" \
        --data-urlencode "disable_web_page_preview=$preview" >/dev/null || true
    }

    ${pkgs.inotify-tools}/bin/inotifywait -m -q -r \
      -e close_write -e moved_to \
      --format '%w%f' /srv/rustypaste/upload \
    | while read -r path; do
        f=$(basename "$path")
        [ -z "$f" ] || [ ! -f "$path" ] && continue
        name=$f
        extra=""
        suffix=''${f##*.}
        case "$suffix" in
          *[!0-9]*|"") ;;
          *)
            if [ "$suffix" != "$f" ] && [ ''${#suffix} -ge 10 ]; then
              name=''${f%.*}
              ts=$suffix
              [ ''${#suffix} -ge 13 ] && ts=$((suffix / 1000))
              expiry=$(date -u -d "@$ts" '+%Y-%m-%d %H:%M UTC' 2>/dev/null || true)
              [ -n "$expiry" ] && extra=" [expires $expiry]"
            fi
            ;;
        esac
        url="https://file.ily.rs/$name"
        case "$path" in
          */oneshot_url/*|*/url/*)
            case "$path" in */oneshot_url/*) extra=" [one-shot]$extra" ;; esac
            target=$(head -c 500 "$path" 2>/dev/null | tr -d '\n')
            send "🔗 New short URL on file.ily.rs: $url$extra
    → $target"
            ;;
          *)
            case "$path" in */oneshot/*) extra=" [one-shot]$extra" ;; esac
            mime=$(${pkgs.file}/bin/file --brief --mime-type "$path" 2>/dev/null || echo unknown)
            bytes=$(stat -c %s "$path" 2>/dev/null || echo 0)
            size=$(${pkgs.coreutils}/bin/numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || echo "$bytes")
            case "$mime" in
              text/*)
                snippet=$(head -c 1000 "$path" 2>/dev/null)
                [ "$bytes" -gt 1000 ] && snippet="$snippet
    […]"
                send "📎 New paste on file.ily.rs: $url$extra ($size)

    $snippet"
                ;;
              image/*)
                send "🖼 New upload on file.ily.rs: $url$extra ($mime, $size)" preview
                ;;
              *)
                send "📎 New upload on file.ily.rs: $url$extra ($mime, $size)"
                ;;
            esac
            ;;
        esac
      done
  '';

  botScript = pkgs.writeShellScript "rustypaste-bot" ''
    set -u
    token=$(tr -d '\n' < ${config.sops.secrets.rustypaste-telegram-token.path})
    dtoken=$(tr -d '\n' < ${config.sops.secrets.rustypaste-delete-token.path})
    api="https://api.telegram.org/bot$token"
    offset_file="/srv/rustypaste/.bot-offset"
    offset=$(cat "$offset_file" 2>/dev/null || echo 0)

    reply() { # $1: message_id to reply to, $2: text
      ${pkgs.curl}/bin/curl -fsS --max-time 10 \
        -X POST "$api/sendMessage" \
        --data-urlencode "chat_id=${chatId}" \
        --data-urlencode "reply_to_message_id=$1" \
        --data-urlencode "text=$2" \
        --data-urlencode "disable_web_page_preview=true" >/dev/null || true
    }

    while :; do
      updates=$(${pkgs.curl}/bin/curl -fsS --max-time 60 "$api/getUpdates" \
        --data-urlencode "timeout=50" \
        --data-urlencode "offset=$offset" \
        --data-urlencode 'allowed_updates=["message"]') || { sleep 5; continue; }
      while IFS= read -r u; do
        [ -z "$u" ] && continue
        uid=$(${pkgs.jq}/bin/jq -r '.update_id' <<<"$u")
        offset=$((uid + 1))
        printf '%s\n' "$offset" > "$offset_file"
        chat=$(${pkgs.jq}/bin/jq -r '.message.chat.id // empty' <<<"$u")
        [ "$chat" = "${chatId}" ] || continue
        cmd=$(${pkgs.jq}/bin/jq -r '.message.text // empty' <<<"$u" \
          | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        case "$cmd" in delete|/delete|/delete@*) ;; *) continue ;; esac
        msgid=$(${pkgs.jq}/bin/jq -r '.message.message_id' <<<"$u")
        orig=$(${pkgs.jq}/bin/jq -r '.message.reply_to_message.text // empty' <<<"$u")
        name=$(grep -oE 'https://file\.ily\.rs/[A-Za-z0-9._-]+' <<<"$orig" \
          | head -1 | sed 's|.*/||')
        if [ -z "$name" ]; then
          reply "$msgid" "Reply \"delete\" to an upload notification to remove that file."
          continue
        fi
        code=$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' --max-time 10 \
          -X DELETE -H "Authorization: $dtoken" "http://localhost:${toString port}/$name")
        if [ "$code" = "200" ]; then
          reply "$msgid" "🗑 Deleted $name."
        else
          reply "$msgid" "Could not delete $name (HTTP $code)."
        fi
      done < <(${pkgs.jq}/bin/jq -c '.result[]?' <<<"$updates" 2>/dev/null)
    done
  '';
in
{
  sops.secrets.rustypaste-delete-token = {
    sopsFile = ../../secrets/rustypaste.yaml;
    key = "delete_token";
    owner = "rustypaste";
    mode = "0400";
  };

  sops.secrets.rustypaste-telegram-token = {
    sopsFile = ../../secrets/rustypaste.yaml;
    key = "telegram_bot_token";
    owner = "rustypaste";
    mode = "0400";
  };

  users.users.rustypaste = {
    isSystemUser = true;
    group = "rustypaste";
    home = "/srv/rustypaste";
    createHome = true;
  };
  users.groups.rustypaste = { };

  systemd.tmpfiles.rules = [
    "d /srv/rustypaste 0750 rustypaste rustypaste -"
    "d /srv/rustypaste/upload 0750 rustypaste rustypaste -"
    "d /srv/rustypaste/upload/oneshot 0750 rustypaste rustypaste -"
    "d /srv/rustypaste/upload/url 0750 rustypaste rustypaste -"
    "d /srv/rustypaste/upload/oneshot_url 0750 rustypaste rustypaste -"
  ];

  systemd.services.rustypaste = {
    description = "rustypaste file/paste server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "rustypaste";
      Group = "rustypaste";
      WorkingDirectory = "/srv/rustypaste";
      ExecStart = "${pkgs.rustypaste}/bin/rustypaste";
      Environment = [
        "CONFIG=${configFile}"
        "DELETE_TOKENS_FILE=${config.sops.secrets.rustypaste-delete-token.path}"
      ];
      Restart = "on-failure";
      RestartSec = 5;
      ReadWritePaths = [ "/srv/rustypaste" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.services.rustypaste-notify = {
    description = "Telegram notification on rustypaste upload";
    wantedBy = [ "multi-user.target" ];
    requires = [ "rustypaste.service" ];
    after = [ "rustypaste.service" ];
    serviceConfig = {
      Type = "simple";
      User = "rustypaste";
      Group = "rustypaste";
      ExecStart = notifyScript;
      Restart = "on-failure";
      RestartSec = 5;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.services.rustypaste-bot = {
    description = "Telegram reply-to-delete bot for rustypaste";
    wantedBy = [ "multi-user.target" ];
    requires = [ "rustypaste.service" ];
    after = [ "rustypaste.service" "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      User = "rustypaste";
      Group = "rustypaste";
      ExecStart = botScript;
      Restart = "on-failure";
      RestartSec = 5;
      ReadWritePaths = [ "/srv/rustypaste" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  services.caddy.virtualHosts."file.ily.rs" = {
    extraConfig = ''
      import favicons
      encode zstd gzip
      root * ${./rustypaste-web}

      @health path /health-ping
      handle @health {
        respond 200
      }

      @page {
        method GET
        path /
      }
      handle @page {
        file_server
      }

      @asset {
        method GET
        file
      }
      handle @asset {
        file_server
      }

      handle {
        header Content-Security-Policy "sandbox allow-same-origin"
        reverse_proxy localhost:${toString port}
      }
    '';
  };
}
