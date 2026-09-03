{
  flake.modules.nixos.server = { config, lib, pkgs, ... }:
  let
    inherit (lib) mkOption types mkIf mkMerge mapAttrsToList optional optionalAttrs;

    siteModule = types.submodule ({ name, ... }: {
      options = {
        enable = lib.mkEnableOption "this site";

        domain = mkOption {
          type = types.str;
          description = "Primary domain name.";
        };

        redirectDomains = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Domains that redirect to the primary domain.";
        };

        repo = mkOption {
          type = types.str;
          description = "Git repository URL.";
        };

        branch = mkOption {
          type = types.str;
          default = "main";
        };

        static = mkOption {
          type = types.bool;
          default = false;
          description = "Serve build output as static files instead of running a Node.js server.";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "Port the Node.js server listens on. Required when static = false.";
        };

        buildOutputDir = mkOption {
          type = types.str;
          default = "dist";
          description = "Build output directory relative to repo root (used for static sites).";
        };

        packageManager = mkOption {
          type = types.enum [ "npm" "pnpm" ];
          default = "pnpm";
        };

        installCommand = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Override install command. Empty string skips install. Null derives from packageManager.";
        };

        buildCommand = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Override build command. Null derives from packageManager (`<pm> run build`).";
        };

        extraBuildPackages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Extra packages on PATH during build (e.g. zola).";
        };

        caddyConfig = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Override Caddy extraConfig for the primary domain. Null uses the default static or reverse_proxy block.";
        };

        entryPoint = mkOption {
          type = types.str;
          default = "dist/server/entry.mjs";
          description = "Node.js entry point relative to repo root.";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Extra environment variables for the running server.";
        };

        buildEnvironment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Extra environment variables for building.";
        };

        dataDir = mkOption {
          type = types.str;
          default = "/srv/${name}";
        };

        readWritePaths = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Paths the server can write to at runtime.";
        };

        afterServices = mkOption {
          type = types.listOf types.str;
          default = [ "forgejo.service" "caddy.service" ];
          description = "Systemd units to wait for before building.";
        };
      };
    });

    cfg = lib.filterAttrs (_: site: site.enable) config.services.site;

    webhookPort = 4323;

    deployments = mapAttrsToList (name: site: {
      inherit site;
      id = name;
      inherit (site) branch dataDir port;
      rebuildDescription = "Clone/pull and build ${site.domain}";
      serveDescription = site.domain;
    }) cfg;

    siteCommands = site:
      let
        pmBin =
          if site.packageManager == "pnpm"
          then "${pkgs.pnpm_10}/bin/pnpm"
          else "${pkgs.nodejs}/bin/npm";
        installCmd =
          if site.installCommand != null then site.installCommand
          else if site.packageManager == "pnpm" then "${pmBin} install --frozen-lockfile"
          else "${pmBin} ci";
        buildCmd =
          if site.buildCommand != null then site.buildCommand
          else "${pmBin} run build";
      in
      { inherit installCmd buildCmd; };
  in
  {
    options.services.site = mkOption {
      type = types.attrsOf siteModule;
      default = {};
      description = "Node.js web site services with git clone, build, and webhook support.";
    };

    config = {
      assertions = mapAttrsToList (name: site: {
        assertion = site.static || site.port != null;
        message = "services.site.${name}.port is required when static = false";
      }) cfg;

      services.telegram-alerts.units = map (d: "${d.id}-rebuild") deployments;

      services.caddy.virtualHosts = mkMerge (mapAttrsToList (_: site:
        {
          ${site.domain}.extraConfig =
            if site.caddyConfig != null then site.caddyConfig
            else if site.static then ''
              import favicons
              root * ${site.dataDir}/repo/${site.buildOutputDir}
              encode zstd gzip
              try_files {path} /index.html
              file_server {
                hide .git
              }
            '' else ''
              import favicons
              reverse_proxy localhost:${toString site.port}
              encode zstd gzip
            '';
        } // builtins.listToAttrs (map (d: {
          name = d;
          value.extraConfig = ''
            redir https://${site.domain}{uri} permanent
          '';
        }) site.redirectDomains)
      ) cfg);

      systemd.services = mkMerge ((map ({ site, id, branch, dataDir, port, rebuildDescription, serveDescription }:
        let c = siteCommands site; in {
          "${id}-rebuild" = {
            description = rebuildDescription;
            after = [ "network-online.target" ] ++ site.afterServices;
            path = [ pkgs.nodejs pkgs.bash ]
              ++ optional (site.packageManager == "pnpm") pkgs.pnpm_10
              ++ site.extraBuildPackages;
            environment = site.buildEnvironment;
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = false;
              ExecStartPre = "+${pkgs.writeShellScript "prepare-${id}" ''
                mkdir -p ${dataDir}
                chown -R ${id}:${id} ${dataDir}
              ''}";
              ExecStart = pkgs.writeShellScript "rebuild-${id}" ''
                set -euo pipefail
                if [ ! -d ${dataDir}/repo/.git ]; then
                  ${pkgs.git}/bin/git clone ${site.repo} ${dataDir}/repo
                fi
                cd ${dataDir}/repo
                ${pkgs.git}/bin/git fetch origin
                ${pkgs.git}/bin/git reset --hard origin/${branch}
                ${lib.optionalString (c.installCmd != "") c.installCmd}
                ${c.buildCmd}
              '';
              ExecStartPost = lib.mkIf (!site.static)
                "+/run/current-system/sw/bin/systemctl restart ${id}";
              User = id;
              Group = id;
            };
          };
        } // optionalAttrs (!site.static) {
          ${id} = {
            description = serveDescription;
            wantedBy = [ "multi-user.target" ];
            unitConfig.ConditionPathExists = "${dataDir}/repo";
            environment = {
              HOST = "127.0.0.1";
              PORT = toString port;
            } // site.environment;
            serviceConfig = {
              Type = "simple";
              WorkingDirectory = "${dataDir}/repo";
              ExecStart = "${pkgs.nodejs}/bin/node ${site.entryPoint}";
              Restart = "on-failure";
              User = id;
              Group = id;
              ReadWritePaths = site.readWritePaths;
            };
          };
        }
      ) deployments) ++ [{
        site-webhook = mkIf (cfg != {}) {
          description = "Webhook listener for site rebuilds";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = let
              allHooks = map (d: {
                id = "${d.id}-rebuild";
                execute-command = "/run/current-system/sw/bin/touch";
                pass-arguments-to-command = [
                  { source = "string"; name = "/run/site-rebuild/${d.id}"; }
                ];
              }) deployments;
              hooksFile = pkgs.writeText "site-hooks.json" (builtins.toJSON allHooks);
            in "${pkgs.webhook}/bin/webhook -hooks ${hooksFile} -ip 127.0.0.1 -port ${toString webhookPort} -verbose";
            Restart = "always";
            DynamicUser = true;
            RuntimeDirectory = "site-rebuild";
          };
        };
      }]);

      systemd.paths = mkMerge (map (d: {
        "${d.id}-rebuild-trigger" = {
          description = "Watch for ${d.id} rebuild trigger";
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = "/run/site-rebuild/${d.id}";
            Unit = "${d.id}-rebuild.service";
          };
        };
      }) deployments);

      users.users = mkMerge (map (d: {
        ${d.id} = {
          isSystemUser = true;
          group = d.id;
          home = d.dataDir;
        };
      }) deployments);

      users.groups = mkMerge (map (d: {
        ${d.id} = {};
      }) deployments);
    };
  };
}
