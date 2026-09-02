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
