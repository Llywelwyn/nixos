{ pkgs, ... }:
let
  port = 4322;
  dataDir = "/srv/website";
  repo = "https://git.ily.rs/lew/website";
in
{
  services.caddy.virtualHosts."wynne.rs" = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
      encode zstd gzip
    '';
  };

  services.caddy.virtualHosts."ily.rs" = {
    extraConfig = ''
      redir https://wynne.rs{uri} permanent
    '';
  };

  systemd.services.wynne = {
    description = "wynne.rs";
    environment = {
      HOST = "127.0.0.1";
      PORT = toString port;
      ASTRO_DB_REMOTE_URL = "file:${dataDir}/data/guestbook.db";
    };
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "${dataDir}/repo";
      ExecStart = "${pkgs.nodejs}/bin/node dist/server/entry.mjs";
      Restart = "on-failure";
      User = "wynne";
      Group = "wynne";
      ReadWritePaths = [ "${dataDir}/data" ];
    };
  };

  # Always rebuilds because wynne bakes DB content (guestbook) into pages at build time
  systemd.services.wynne-rebuild = {
    description = "Clone/pull and build wynne.rs";
    after = [ "network-online.target" ];
    path = [ pkgs.nodejs pkgs.bash ];
    environment = {
      ASTRO_DB_REMOTE_URL = "file:${dataDir}/data/guestbook.db";
    };
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStartPre = "+${pkgs.writeShellScript "prepare-wynne" ''
        mkdir -p ${dataDir}/data
        chown -R wynne:wynne ${dataDir}
      ''}";
      ExecStart = pkgs.writeShellScript "rebuild-wynne" ''
        set -euo pipefail
        if [ ! -d ${dataDir}/repo/.git ]; then
          ${pkgs.git}/bin/git clone ${repo} ${dataDir}/repo
        fi
        cd ${dataDir}/repo
        ${pkgs.git}/bin/git fetch origin
        ${pkgs.git}/bin/git reset --hard origin/master
        ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile
	${pkgs.pnpm}/bin/pnpm build
      '';
      # + prefix runs this line as root (wynne user can't restart services)
      ExecStartPost = "+/run/current-system/sw/bin/systemctl restart wynne";
      User = "wynne";
      Group = "wynne";
    };
  };

  # Watches a trigger file, starts wynne-rebuild when touched
  systemd.paths.wynne-rebuild-trigger = {
    description = "Watch for wynne rebuild trigger";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${dataDir}/trigger";
      Unit = "wynne-rebuild.service";
    };
  };

  systemd.services.wynne-webhook = {
    description = "Webhook listener for wynne.rs";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = let
        hooks = pkgs.writeText "wynne-hooks.json" (builtins.toJSON [{
          id = "wynne-rebuild";
          execute-command = "/run/current-system/sw/bin/touch";
          pass-arguments-to-command = [
            { source = "string"; name = "${dataDir}/trigger"; }
          ];
        }]);
      in "${pkgs.webhook}/bin/webhook -hooks ${hooks} -port ${toString (port + 1)} -verbose";
      Restart = "always";
      User = "wynne";
      Group = "wynne";
    };
  };

  users.users.wynne = {
    isSystemUser = true;
    group = "wynne";
    home = dataDir;
  };
  users.groups.wynne = {};
}
