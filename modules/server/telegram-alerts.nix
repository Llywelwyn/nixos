{
  flake.modules.nixos.server = { config, pkgs, lib, ... }:
  let
    chatId = toString config.services.telegram-alerts.chatId;
    host = config.networking.hostName;

    alertScript = pkgs.writeShellScript "telegram-alert" ''
      set -u
      unit="$1"
      token=$(tr -d '\n' < ${config.sops.secrets.telegram_bot_token.path})
      state=$(${pkgs.systemd}/bin/systemctl is-failed "$unit" 2>/dev/null || true)
      log=$(${pkgs.systemd}/bin/journalctl -u "$unit" -n 30 --no-pager -o cat 2>/dev/null | tail -c 3500)
      text="[${host}] $unit failed (state: $state)

      --- last log ---
      $log"
      ${pkgs.curl}/bin/curl -fsS --max-time 10 \
        -X POST "https://api.telegram.org/bot$token/sendMessage" \
        --data-urlencode "chat_id=${chatId}" \
        --data-urlencode "text=$text" \
        --data-urlencode "disable_web_page_preview=true" >/dev/null
    '';

    diskAlertScript = pkgs.writeShellScript "disk-usage-alert" ''
      set -u
      threshold=85
      usage=$(${pkgs.coreutils}/bin/df --output=pcent /srv | tail -n 1 | tr -dc '0-9')
      [ "$usage" -lt "$threshold" ] && exit 0
      token=$(tr -d '\n' < ${config.sops.secrets.telegram_bot_token.path})
      ${pkgs.curl}/bin/curl -fsS --max-time 10 \
        -X POST "https://api.telegram.org/bot$token/sendMessage" \
        --data-urlencode "chat_id=${chatId}" \
        --data-urlencode "text=[${host}] disk usage for /srv at $usage% (threshold $threshold%)" \
        --data-urlencode "disable_web_page_preview=true" >/dev/null
    '';

    alertedServices = config.services.telegram-alerts.units
      ++ map (n: "podman-${n}") (lib.attrNames config.virtualisation.oci-containers.containers);
  in
  {
    options.services.telegram-alerts = {
      units = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Systemd units that send a Telegram alert on failure. Merged from all modules; container units are added automatically.";
      };
      chatId = lib.mkOption {
        type = lib.types.int;
        default = 8669496383;
        description = "Telegram chat that receives alerts and bot traffic.";
      };
    };

    config = {
      systemd.services = lib.mkMerge [
        {
          "telegram-alert@" = {
            description = "Send Telegram alert for failed unit %i";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${alertScript} %i";
            };
          };
          disk-usage-alert = {
            description = "Telegram alert when disk usage crosses threshold";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = diskAlertScript;
            };
          };
        }
        (lib.genAttrs alertedServices (_: {
          unitConfig.OnFailure = [ "telegram-alert@%n.service" ];
        }))
      ];

      systemd.timers.disk-usage-alert = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
  };
}
