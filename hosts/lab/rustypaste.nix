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
    token=$(tr -d '\n' < ${config.sops.secrets.telegram-alert-token.path})
    ${pkgs.inotify-tools}/bin/inotifywait -m -q -r \
      -e close_write -e moved_to \
      --format '%w%f' /srv/rustypaste/upload \
    | while read -r path; do
        f=$(basename "$path")
        [ -z "$f" ] && continue
        name=$(printf '%s' "$f" | sed -E 's/\.[0-9]+$//')
        extra=""
        case "$path" in
          */oneshot/*) extra=" [one-shot]" ;;
          */url/*)     extra=" [url]" ;;
        esac
        suffix=''${f##*.}
        case "$suffix" in
          *[!0-9]*|"") ;;
          *)
            if [ "$suffix" != "$f" ] && [ ''${#suffix} -ge 10 ]; then
              ts=$suffix
              [ ''${#suffix} -ge 13 ] && ts=$((suffix / 1000))
              expiry=$(date -u -d "@$ts" '+%Y-%m-%d %H:%M UTC' 2>/dev/null || true)
              [ -n "$expiry" ] && extra="$extra [expires $expiry]"
            fi
            ;;
        esac
        ${pkgs.curl}/bin/curl -fsS --max-time 10 \
          -X POST "https://api.telegram.org/bot$token/sendMessage" \
          --data-urlencode "chat_id=${chatId}" \
          --data-urlencode "text=📎 New upload on file.ily.rs: https://file.ily.rs/$name$extra" \
          --data-urlencode "disable_web_page_preview=true" >/dev/null || true
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
      ExecStart = notifyScript;
      Restart = "on-failure";
      RestartSec = 5;
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
