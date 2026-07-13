{
  flake.modules.nixos.server = { config, ... }: {
    sops.secrets.miniflux-admin-credentials = {
      sopsFile = ../../secrets/miniflux.yaml;
      key = "admin-credentials";
    };

    services = {
      miniflux = {
        enable = true;
        adminCredentialsFile = config.sops.secrets.miniflux-admin-credentials.path;
        config = {
          LISTEN_ADDR = "127.0.0.1:8080";
          BASE_URL = "https://rss.ily.rs/";
        };
      };

      telegram-alerts.units = [ "miniflux" ];
      uptime-page.probes.rss = { url = "https://rss.ily.rs"; order = 105; };

      caddy.virtualHosts."rss.ily.rs" = {
        extraConfig = ''
          import favicons
          reverse_proxy localhost:8080
          encode zstd gzip
        '';
      };
    };
  };
}
