{
  flake.modules.nixos.server = { config, ... }:
  let
    cfg = config.services.uptime-page;
  in
  {
    services.telegram-alerts.units = [ "uptime" ];

    services.uptime-page = {
      enable = true;
      displayDays = 90;
      intro = ''
        This page is written in Bash. It tracks ${toString cfg.displayDays} days of historical uptime
        data for various services. This page regenerates every ${toString cfg.categories.services.intervalSeconds} seconds.
        Probes run from the same machine that hosts these services, so a
        gap (.) can also mean the machine itself was down.
      '';

      categories.services = {
        description = "My services";
        intervalSeconds = 60;
        order = 1;
      };
      categories.external = {
        description = "Other services";
        intervalSeconds = 300;
        hideUrls = true;
        order = 2;
      };

      probes = {
        co-surf   = { url = "https://co-surf.com"; category = "external"; };
        frontline = { url = "https://essexfrontline.org.uk"; category = "external"; };
      };
    };
  };
}
