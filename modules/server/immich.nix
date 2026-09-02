{
  flake.modules.nixos.server = {
    services = {
      immich = {
        enable = true;
        mediaLocation = "/srv/immich";
        settings.server.externalDomain = "https://photos.ily.rs";
      };

      telegram-alerts.units = [ "immich-server" ];
      uptime-page.probes.photos = { url = "https://photos.ily.rs"; order = 35; };

      caddy.virtualHosts."photos.ily.rs" = {
        extraConfig = ''
          import favicons
          reverse_proxy localhost:2283
          encode zstd gzip
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /srv/immich 0750 immich immich -"
    ];
  };
}
