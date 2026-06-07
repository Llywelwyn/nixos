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
      expose_list = true;
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
      random_url = { type = "alphanumeric"; length = 3; };
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
      # Uploads are permanent by default; this only reaps files that were
      # uploaded with an explicit expiry.
      duplicate_files = false;
      delete_expired_files = { enabled = true; interval = "1h"; };
    };
  };

  configFile = (pkgs.formats.toml { }).generate "rustypaste-config.toml" settings;

  notifyScript = pkgs.writeShellScript "rustypaste-notify" ''
    set -u
    token=$(tr -d '\n' < ${config.sops.secrets.telegram-alert-token.path})
    ${pkgs.inotify-tools}/bin/inotifywait -m -q \
      -e close_write -e moved_to \
      --format '%f' /srv/rustypaste/upload \
    | while read -r f; do
        [ -z "$f" ] && continue
        # On-disk name carries an expiry suffix (.<unixtime>); the served
        # path is the base name, so strip it for the link.
        name=$(printf '%s' "$f" | sed -E 's/\.[0-9]+$//')
        ${pkgs.curl}/bin/curl -fsS --max-time 10 \
          -X POST "https://api.telegram.org/bot$token/sendMessage" \
          --data-urlencode "chat_id=${chatId}" \
          --data-urlencode "text=📎 New upload on file.ily.rs: https://file.ily.rs/$name" \
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

  # Per-upload Telegram notification (rustypaste has no built-in webhook).
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

      # upload page at the root
      @page {
        method GET
        path /
      }
      handle @page {
        file_server
      }

      # static assets (joi.png, etc.) if they exist on disk
      @asset {
        method GET
        file
      }
      handle @asset {
        file_server
      }

      # everything else (uploads, downloads, /list) -> rustypaste
      handle {
        reverse_proxy localhost:${toString port}
      }
    '';
  };
}
