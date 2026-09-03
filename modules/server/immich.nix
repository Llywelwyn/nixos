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

      caddy.virtualHosts."photos.ily.rs".extraConfig = "import proxy 2283";
    };

    systemd.tmpfiles.rules = [
      "d /srv/immich 0750 immich immich -"
    ];
  };
}
