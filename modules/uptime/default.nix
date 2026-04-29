{ config, lib, pkgs, ... }:
let
  cfg = config.services.uptime;

  servicesEnv = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: url: "${name} ${url}") cfg.services);

  runScript = pkgs.writeShellApplication {
    name = "uptime-run";
    runtimeInputs = with pkgs; [ curl gawk coreutils ];
    text = builtins.readFile ./run.sh;
  };
in
{
  options.services.uptime = {
    enable = lib.mkEnableOption "minimal text-only uptime status page";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "Probe interval, passed to the timer's OnUnitActiveSec.";
    };

    outputPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/uptime/status.txt";
      description = ''
        Path where the rendered status page is written.
        Must be writable by the uptime user. The default lives inside the
        unit's StateDirectory, which is created and owned automatically.
      '';
    };

    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = { forgejo = "https://git.ily.rs"; };
      description = "Map of service name to URL to probe.";
    };

    retentionDays = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "How many days of log entries to keep on disk.";
    };

    displayDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "How many days of history to render in the bar.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.displayDays <= cfg.retentionDays;
      message = "services.uptime.displayDays (${toString cfg.displayDays}) must be <= retentionDays (${toString cfg.retentionDays}).";
    }];

    users.users.uptime = {
      isSystemUser = true;
      group = "uptime";
      home = "/var/lib/uptime";
    };
    users.groups.uptime = {};

    systemd.services.uptime = {
      description = "Probe configured services and render the status page";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        SERVICES = servicesEnv;
        OUTPUT_PATH = cfg.outputPath;
        RETENTION_DAYS = toString cfg.retentionDays;
        DISPLAY_DAYS = toString cfg.displayDays;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe runScript;
        User = "uptime";
        Group = "uptime";
        StateDirectory = "uptime";
        StateDirectoryMode = "0755";
        UMask = "0022";
      };
    };

    systemd.timers.uptime = {
      description = "Periodic uptime probe";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.interval;
        Unit = "uptime.service";
      };
    };
  };
}
