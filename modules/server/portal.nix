{
  flake.modules.nixos.server = { config, pkgs, ... }:
  let
    gate = pkgs.writeTextDir "index.html" (builtins.readFile ./portal/gate.html);
  in
  {
    sops.secrets = {
      portal-pin = {
        sopsFile = ../../secrets/portal.yaml;
        key = "pin";
      };
      portal-home = {
        sopsFile = ../../secrets/portal.yaml;
        key = "home_html";
        owner = config.services.caddy.user;
        path = "/run/portal/index.html";
      };
    };

    sops.templates."portal.env".content = "PORTAL_PIN=${config.sops.placeholder.portal-pin}";

    services.caddy = {
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-ratelimit@v0.1.0" ];
        hash = "sha256-eET4cfn1OGyl8rtq8/dO95eM+hvjLPi9IyyWz6vT5QQ=";
      };

      globalConfig = ''
        order rate_limit before basic_auth
      '';

      environmentFile = config.sops.templates."portal.env".path;

      virtualHosts = {
        "wynne.rs".extraConfig = ''
          import favicons
          encode zstd gzip

          @authed header Cookie *pin={$PORTAL_PIN}*
          handle @authed {
            root * /run/portal
            file_server
          }
          handle {
            rate_limit {
              zone pin_attempts {
                match {
                  header Cookie *pin=*
                }
                key {remote_host}
                events 5
                window 5m
              }
            }
            root * ${gate}
            file_server
          }
        '';

        "www.wynne.rs".extraConfig = ''
          redir https://wynne.rs{uri} permanent
        '';
      };
    };
  };
}
