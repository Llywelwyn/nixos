{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types mkIf mkMerge mapAttrsToList mapAttrs' nameValuePair
    concatLists optional;

  siteModule = types.submodule ({ name, ... }: {
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
        default = [ "forgejo.service" ];
        description = "Systemd units to wait for before building.";
      };
    };
  });

  cfg = config.services.site;

  webhookPort = 4323;

  siteHelpers = name: site:
    let
      pmBin =
        if site.packageManager == "pnpm"
        then "${pkgs.pnpm}/bin/pnpm"
        else "${pkgs.nodejs}/bin/npm";
      installCmd =
        if site.packageManager == "pnpm"
        then "${pmBin} install --frozen-lockfile"
        else "${pmBin} ci";
    in
    { inherit pmBin installCmd; dataDir = site.dataDir; };
in
{
  options.services.site = mkOption {
    type = types.attrsOf siteModule;
    default = {};
    description = "Node.js web site services with git clone, build, and webhook support.";
  };

  config = {
    services.caddy.virtualHosts = mkMerge (mapAttrsToList (name: site:
      {
        ${site.domain}.extraConfig = if site.static then ''
          root * ${site.dataDir}/repo/${site.buildOutputDir}
          encode zstd gzip
          try_files {path} /index.html
          file_server
        '' else ''
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

    systemd.services = mkMerge ((mapAttrsToList (name: site:
      let h = siteHelpers name site; in {
        "${name}-rebuild" = {
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
              mkdir -p ${h.dataDir}
              chown -R ${name}:${name} ${h.dataDir}
            ''}";
            ExecStart = pkgs.writeShellScript "rebuild-${name}" ''
              set -euo pipefail
              if [ ! -d ${h.dataDir}/repo/.git ]; then
                ${pkgs.git}/bin/git clone ${site.repo} ${h.dataDir}/repo
              fi
              cd ${h.dataDir}/repo
              ${pkgs.git}/bin/git fetch origin
              ${pkgs.git}/bin/git reset --hard origin/${site.branch}
              ${h.installCmd}
              ${h.pmBin} run build
            '';
            ExecStartPost = lib.mkIf (!site.static)
              "+/run/current-system/sw/bin/systemctl restart ${name}";
            User = name;
            Group = name;
          };
        };
      } // lib.optionalAttrs (!site.static) {
        ${name} = {
          description = site.domain;
          environment = {
            HOST = "127.0.0.1";
            PORT = toString site.port;
          } // site.environment;
          serviceConfig = {
            Type = "simple";
            WorkingDirectory = "${h.dataDir}/repo";
            ExecStart = "${pkgs.nodejs}/bin/node ${site.entryPoint}";
            Restart = "on-failure";
            User = name;
            Group = name;
            ReadWritePaths = site.readWritePaths;
          };
        };
      }
    ) cfg) ++ [{
      site-webhook = mkIf (cfg != {}) {
        description = "Webhook listener for site rebuilds";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = let
            allHooks = mapAttrsToList (name: site: {
              id = "${name}-rebuild";
              execute-command = "/run/current-system/sw/bin/touch";
              pass-arguments-to-command = [
                { source = "string"; name = "/run/site-rebuild/${name}"; }
              ];
            }) cfg;
            hooksFile = pkgs.writeText "site-hooks.json" (builtins.toJSON allHooks);
          in "${pkgs.webhook}/bin/webhook -hooks ${hooksFile} -port ${toString webhookPort} -verbose";
          Restart = "always";
          DynamicUser = true;
          RuntimeDirectory = "site-rebuild";
        };
      };
    }]);

    systemd.paths = mkMerge (mapAttrsToList (name: site: {
      "${name}-rebuild-trigger" = {
        description = "Watch for ${name} rebuild trigger";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          PathModified = "/run/site-rebuild/${name}";
          Unit = "${name}-rebuild.service";
        };
      };
    }) cfg);

    users.users = mkMerge (mapAttrsToList (name: site: {
      ${name} = {
        isSystemUser = true;
        group = name;
        home = site.dataDir;
      };
    }) cfg);

    users.groups = mkMerge (mapAttrsToList (name: _: {
      ${name} = {};
    }) cfg);
  };
}
