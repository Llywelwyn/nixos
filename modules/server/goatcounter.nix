{
  flake.modules.nixos.server = { config, lib, pkgs, ... }:
  let
    goatcounter = config.services.goatcounter.package;
    # jq shim: goatcounter's caddy parser expects remote_addr (Caddy ≥2.5 logs
    # remote_ip) and ignores the vhost, so the host is folded into the path.
    mkImport = host: excludes: {
      description = "Import ${host} hits from Caddy logs into GoatCounter";
      wantedBy = [ "multi-user.target" ];
      after = [ "goatcounter.service" "caddy.service" ];
      wants = [ "goatcounter.service" ];
      path = [ pkgs.coreutils pkgs.jq goatcounter ];
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "goatcounter-import-${host}" ''
          set -o pipefail
          export GOATCOUNTER_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/api_key")"
          tail -n0 -F /var/log/caddy/access-${host}.log \
            | jq --unbuffered -c '
                .request.remote_addr = .request.remote_ip
                | .request.uri = ("/" + .request.host + .request.uri)' \
            | goatcounter import -silent -format caddy \
                -site https://stats.ily.rs \
                -exclude '!method:GET' \
                -exclude 'status:re:^[345]' \
                ${lib.concatMapStringsSep " " (e: "-exclude ${lib.escapeShellArg e}") excludes} \
                -
        '';
        User = "caddy";
        Group = "caddy";
        LoadCredential = "api_key:${config.sops.secrets.goatcounter_api_key.path}";
        Restart = "always";
        RestartSec = 30;
      };
    };
  in
  {
    services.goatcounter = {
      enable = true;
      port = 8081;
      proxy = true;
    };

    services.uptime-page.probes.stats = { url = "https://stats.ily.rs"; order = 110; };

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

    systemd.services.goatcounter-import-file = mkImport "file.ily.rs" [
      ''path:re:^/file\.ily\.rs/$''
      ''path:re:^/file\.ily\.rs/(health-ping$|favicon|apple-touch-icon|robots\.txt)''
    ];

    systemd.services.goatcounter-import-lite = mkImport "lite.ily.rs" [
      "user_agent:curl"
      ''path:re:^/lite\.ily\.rs/(favicon|apple-touch-icon|robots\.txt)''
      ''path:re:\.(css|xml|png|jpe?g|gif|webp|ico|webm|ogg|mp3)$''
    ];

    systemd.services.goatcounter-import-penfield = mkImport "penfield.ily.rs" [
      "user_agent:curl"
      ''path:re:^/penfield\.ily\.rs/(favicon|apple-touch-icon|robots\.txt)''
    ];

    environment.systemPackages = [ goatcounter ];
  };
}
