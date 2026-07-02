# Self-hosted analytics at stats.ily.rs. One GoatCounter site tracks every
# domain; pages prefix location.host onto the path so domains stay
# distinguishable in a single dashboard. Site creation is a one-time manual
# step (see docs/plans/2026-07-02-goatcounter-design.md).
{ config, ... }:
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

  environment.systemPackages = [ config.services.goatcounter.package ];
}
