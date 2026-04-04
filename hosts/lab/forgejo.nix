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
      reverse_proxy localhost:${toString srv.HTTP_PORT}
    '';
  };

  services.forgejo = {
    enable = true;
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.ily.rs";
        ROOT_URL = "https://git.ily.rs/";
        HTTP_PORT = 3000;
        START_SSH_SERVER = true;
        SSH_PORT = 2222;
        SSH_LISTEN_PORT = 2222;
      };
      service.DISABLE_REGISTRATION = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 2222 ];

  systemd.services.forgejo.preStart = let
    adminCmd = "${lib.getExe cfg.package} admin user";
    pwd = config.sops.secrets.forgejo-admin-password;
  in lib.mkAfter ''
    ${adminCmd} create --admin --email "lew@ily.rs" \
      --username lew --password "$(tr -d '\n' < ${pwd.path})" || true
  '';
}
