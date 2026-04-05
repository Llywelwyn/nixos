{ pkgs, ... }:
let
  port = 4322;
  dataDir = "/srv/wynne";
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
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
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

  users.users.wynne = {
    isSystemUser = true;
    group = "wynne";
    home = dataDir;
  };
  users.groups.wynne = {};
}
