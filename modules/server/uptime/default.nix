{
  flake.modules.nixos.server = { config, lib, pkgs, ... }:
  let
    cfg = config.services.uptime-page;

    probeSubmodule = lib.types.submodule {
      options = {
        url = lib.mkOption {
          type = lib.types.str;
          description = "URL to probe.";
        };
        category = lib.mkOption {
          type = lib.types.str;
          default = "services";
          description = "Category this probe is rendered under.";
        };
        order = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "Sort key within the category (ties break on name).";
        };
      };
    };

    categorySubmodule = lib.types.submodule {
      options = {
        description = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Free-form text shown above this category's table.";
        };
        intervalSeconds = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Minimum interval between probes for services in this category.";
        };
        hideUrls = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "If true, omit the URL column when rendering services in this category.";
        };
        order = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "Sort key for category render order (ties break on name).";
        };
      };
    };

    byOrder = a: b:
      if a.value.order != b.value.order
      then a.value.order < b.value.order
      else a.name < b.name;

    sortedCategories = lib.sort byOrder (lib.attrsToList cfg.categories);
    probesFor = catName: lib.sort byOrder
      (lib.filter (p: p.value.category == catName) (lib.attrsToList cfg.probes));

    configFile = pkgs.writeText "uptime-config" ((lib.concatStringsSep "\n" (
      (lib.imap0 (i: cat:
        "CAT\t${toString i}\t${toString cat.value.intervalSeconds}\t${if cat.value.hideUrls then "1" else "0"}\t${cat.value.description}"
      ) sortedCategories)
      ++
      (lib.concatLists (lib.imap0 (i: cat:
        map (p: "SVC\t${toString i}\t${p.name}\t${p.value.url}") (probesFor cat.name)
      ) sortedCategories))
    )) + "\n");

    introFile = pkgs.writeText "uptime-intro" cfg.intro;

    catIntervals = map (c: c.intervalSeconds) (lib.attrValues cfg.categories);
    timerSeconds =
      if catIntervals == []
      then 60
      else lib.foldl' (a: b: if a < b then a else b) 86400 catIntervals;

    runScript = pkgs.writeShellApplication {
      name = "uptime-run";
      runtimeInputs = with pkgs; [ curl gawk coreutils ];
      text = builtins.readFile ./run.sh;
    };
  in
  {
    options.services.uptime-page = {
      enable = lib.mkEnableOption "minimal text-only uptime status page";

      outputPath = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/uptime/status.txt";
        description = ''
          Path where the rendered status page is written.
          Must be writable by the uptime user. The default lives inside the
          unit's StateDirectory, which is created and owned automatically.
        '';
      };

      intro = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Free-form text shown at the top of the status page (before any categories).";
      };

      categories = lib.mkOption {
        type = lib.types.attrsOf categorySubmodule;
        default = {};
        description = "Service categories, rendered as separate tables sorted by order.";
      };

      probes = lib.mkOption {
        type = lib.types.attrsOf probeSubmodule;
        default = {};
        example = { git = { url = "https://git.ily.rs"; order = 40; }; };
        description = "Services to probe, keyed by row label (also the log filename). Merged from all modules.";
      };

      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 90;
        description = "How many days of log entries to keep on disk.";
      };

      displayDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "How many days of history to render in the long-term bar.";
      };

      displayHours = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "How many hours of recent history to render in the short-term bar (1 cell = 1 hour).";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [{
        assertion = cfg.displayDays <= cfg.retentionDays;
        message = "services.uptime-page.displayDays (${toString cfg.displayDays}) must be <= retentionDays (${toString cfg.retentionDays}).";
      }] ++ lib.mapAttrsToList (name: probe: {
        assertion = cfg.categories ? ${probe.category};
        message = "services.uptime-page.probes.${name} references undefined category \"${probe.category}\".";
      }) cfg.probes;

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
          CONFIG_PATH = "${configFile}";
          INTRO_PATH = "${introFile}";
          OUTPUT_PATH = cfg.outputPath;
          RETENTION_DAYS = toString cfg.retentionDays;
          DISPLAY_DAYS = toString cfg.displayDays;
          DISPLAY_HOURS = toString cfg.displayHours;
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
          OnUnitActiveSec = "${toString timerSeconds}s";
          Unit = "uptime.service";
        };
      };
    };
  };
}
