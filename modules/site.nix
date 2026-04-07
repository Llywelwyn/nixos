{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types mkIf mkMerge mapAttrsToList optional;

  siteModule = types.submodule ({ name, config, ... }: {
    options = {
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

      port = mkOption {
        type = types.port;
        description = "Port the Node.js server listens on.";
      };

      webhookPort = mkOption {
        type = types.port;
        default = config.port + 1;
        description = "Port for the rebuild webhook listener.";
      };

      packageManager = mkOption {
        type = types.enum [ "npm" "pnpm" ];
        default = "pnpm";
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
        description = "Extra paths the server can write to at runtime.";
      };

      afterServices = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Systemd units to wait for before building.";
      };
    };
  });

  cfg = config.services.site;

  makeSiteConfig = name: site:
    let
      dataDir = site.dataDir;
      pmBin =
        if site.packageManager == "pnpm"
        then "${pkgs.pnpm}/bin/pnpm"
        else "${pkgs.nodejs}/bin/npm";
      installCmd =
        if site.packageManager == "pnpm"
        then "${pmBin} install --frozen-lockfile"
        else "${pmBin} ci";
    in
    {
      services.caddy.virtualHosts = {
        ${site.domain} = {
          extraConfig = ''
            reverse_proxy localhost:${toString site.port}
            encode zstd gzip
          '';
        };
      } // builtins.listToAttrs (map (d: {
        name = d;
        value.extraConfig = ''
          redir https://${site.domain}{uri} permanent
        '';
      }) site.redirectDomains);

      systemd.services.${name} = {
        description = site.domain;
        environment = {
          HOST = "127.0.0.1";
          PORT = toString site.port;
        } // site.environment;
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = "${dataDir}/repo";
          ExecStart = "${pkgs.nodejs}/bin/node ${site.entryPoint}";
          Restart = "on-failure";
          User = name;
          Group = name;
          ReadWritePaths = site.readWritePaths;
        };
      };

      systemd.services."${name}-rebuild" = {
        description = "Clone/pull and build ${site.domain}";
        after = [ "network-online.target" ] ++ site.afterServices;
        path = [ pkgs.nodejs pkgs.bash ]
          ++ optional (site.packageManager == "pnpm") pkgs.pnpm;
        environment = site.buildEnvironment;
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = false;
          ExecStartPre = "+${pkgs.writeShellScript "prepare-${name}" ''
            mkdir -p ${dataDir}
            chown -R ${name}:${name} ${dataDir}
          ''}";
          ExecStart = pkgs.writeShellScript "rebuild-${name}" ''
            set -euo pipefail
            if [ ! -d ${dataDir}/repo/.git ]; then
              ${pkgs.git}/bin/git clone ${site.repo} ${dataDir}/repo
            fi
            cd ${dataDir}/repo
            ${pkgs.git}/bin/git fetch origin
            ${pkgs.git}/bin/git reset --hard origin/${site.branch}
            ${installCmd}
            ${pmBin} run build
          '';
          ExecStartPost = "+/run/current-system/sw/bin/systemctl restart ${name}";
          User = name;
          Group = name;
        };
      };

      systemd.paths."${name}-rebuild-trigger" = {
        description = "Watch for ${name} rebuild trigger";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          PathModified = "${dataDir}/trigger";
          Unit = "${name}-rebuild.service";
        };
      };

      systemd.services."${name}-webhook" = {
        description = "Webhook listener for ${site.domain}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = let
            hooks = pkgs.writeText "${name}-hooks.json" (builtins.toJSON [{
              id = "${name}-rebuild";
              execute-command = "/run/current-system/sw/bin/touch";
              pass-arguments-to-command = [
                { source = "string"; name = "${dataDir}/trigger"; }
              ];
            }]);
          in "${pkgs.webhook}/bin/webhook -hooks ${hooks} -port ${toString site.webhookPort} -verbose";
          Restart = "always";
          User = name;
          Group = name;
        };
      };

      users.users.${name} = {
        isSystemUser = true;
        group = name;
        home = dataDir;
      };
      users.groups.${name} = {};
    };

in
{
  options.services.site = mkOption {
    type = types.attrsOf siteModule;
    default = {};
    description = "Node.js web site services with git clone, build, and webhook support.";
  };

  config = mkIf (cfg != {}) (mkMerge (mapAttrsToList makeSiteConfig cfg));
}
