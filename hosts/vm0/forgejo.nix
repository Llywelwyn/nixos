{ config, lib, pkgs, ... }:
let
  cfg = config.services.forgejo;
  srv = cfg.settings.server;
  goatcounterFooter = pkgs.writeText "forgejo-footer.tmpl" ''
    <script>
      window.goatcounter = { path: function (p) { return location.host + p } };
    </script>
    <script data-goatcounter="https://stats.ily.rs/count" async src="https://stats.ily.rs/count.js"></script>
  '';
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
      };
      service.DISABLE_REGISTRATION = true;
      webhook = {
        ALLOWED_HOST_LIST = "loopback";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 4201 ];

  services.telegram-alerts.units = [ "forgejo" ];
  services.uptime-page.probes.git = { url = "https://git.ily.rs"; order = 40; };

  systemd.tmpfiles.settings."10-forgejo" = {
    "${cfg.customDir}/templates"."d" = {
      user = "forgejo";
      group = "forgejo";
      mode = "0755";
    };
    "${cfg.customDir}/templates/custom"."d" = {
      user = "forgejo";
      group = "forgejo";
      mode = "0755";
    };
    "${cfg.customDir}/templates/custom/footer.tmpl"."C+" = {
      argument = "${goatcounterFooter}";
      user = "forgejo";
      group = "forgejo";
      mode = "0644";
    };
  };

  systemd.services.forgejo.preStart = let
    adminCmd = "${lib.getExe cfg.package} admin user";
    pwd = config.sops.secrets.forgejo-admin-password;
    marker = "${cfg.stateDir}/.admin-bootstrapped";
  in lib.mkAfter ''
    if [ ! -e ${marker} ]; then
      if ${adminCmd} list | grep -qE '^[0-9]+\s+lew\s'; then
        echo "admin user 'lew' already exists, marking bootstrapped"
      else
        ${adminCmd} create --admin --email "l@ily.rs" \
          --username lew --password "$(tr -d '\n' < ${pwd.path})"
      fi
      touch ${marker}
    fi
  '';
}
