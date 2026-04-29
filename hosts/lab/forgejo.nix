{ config, lib, ... }:
let
  cfg = config.services.forgejo;
  srv = cfg.settings.server;
in
{
  sops.secrets.forgejo-admin-password = {
    sopsFile = ../../secrets/forgejo.yaml;
    owner = "forgejo";
  };

  services.caddy.virtualHosts."git.ily.rs" = {
    extraConfig = ''
      import favicons
      reverse_proxy localhost:${toString srv.HTTP_PORT}
      encode zstd gzip
    '';
  };

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.ily.rs";
        ROOT_URL = "https://git.ily.rs/";
        HTTP_PORT = 3000;
        SSH_DOMAIN = "git.ily.rs";
        START_SSH_SERVER = true;
        SSH_PORT = 4201;
        SSH_LISTEN_PORT = 4201;
        DISABLE_HTTP_GIT = false;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };
      webhook = {
        ALLOWED_HOST_LIST = "loopback";
      };
    };
  };


  networking.firewall.allowedTCPPorts = [ 4201 ];

  systemd.services.forgejo.preStart = let
    adminCmd = "${lib.getExe cfg.package} admin user";
    pwd = config.sops.secrets.forgejo-admin-password;
    marker = "${cfg.stateDir}/.admin-bootstrapped";
  in lib.mkAfter ''
    if [ ! -e ${marker} ]; then
      if ${adminCmd} list | grep -qE '^[0-9]+\s+lew\s'; then
        echo "admin user 'lew' already exists, marking bootstrapped"
      else
        ${adminCmd} create --admin --email "lew@ily.rs" \
          --username lew --password "$(tr -d '\n' < ${pwd.path})"
      fi
      touch ${marker}
    fi
  '';
}
