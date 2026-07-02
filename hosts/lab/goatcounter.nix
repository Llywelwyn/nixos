{ config, pkgs, ... }:
let
  goatcounter = config.services.goatcounter.package;
  # jq shim: goatcounter's caddy parser expects remote_addr (Caddy ≥2.5 logs
  # remote_ip) and ignores the vhost, so the host is folded into the path.
  importFileLog = pkgs.writeShellScript "goatcounter-import-file" ''
    set -o pipefail
    export GOATCOUNTER_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/api_key")"
    tail -n0 -F /var/log/caddy/access-file.ily.rs.log \
      | jq --unbuffered -c '
          .request.remote_addr = .request.remote_ip
          | .request.uri = ("/" + .request.host + .request.uri)' \
      | goatcounter import -silent -format caddy \
          -site https://stats.ily.rs \
          -exclude '!method:GET' \
          -exclude 'status:re:^[345]' \
          -exclude 'path:re:^/file\.ily\.rs/$' \
          -exclude 'path:re:^/file\.ily\.rs/(health-ping$|favicon|apple-touch-icon|robots\.txt)' \
          -
  '';
in
{
  services.goatcounter = {
    enable = true;
    port = 8081;
    proxy = true;
  };

  services.caddy.virtualHosts."stats.ily.rs" = {
    extraConfig = ''
      import favicons
      reverse_proxy localhost:8081
      encode zstd gzip
    '';
  };

  sops.secrets.goatcounter_api_key = {
    sopsFile = ../../secrets/goatcounter.yaml;
    key = "api_key";
  };

  systemd.services.goatcounter-import-file = {
    description = "Import file.ily.rs downloads from Caddy logs into GoatCounter";
    wantedBy = [ "multi-user.target" ];
    after = [ "goatcounter.service" "caddy.service" ];
    wants = [ "goatcounter.service" ];
    path = [ pkgs.coreutils pkgs.jq goatcounter ];
    serviceConfig = {
      ExecStart = importFileLog;
      User = "caddy";
      Group = "caddy";
      LoadCredential = "api_key:${config.sops.secrets.goatcounter_api_key.path}";
      Restart = "always";
      RestartSec = 30;
    };
  };

  environment.systemPackages = [ goatcounter ];
}
