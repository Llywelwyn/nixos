{ config, ... }:
{
  flake.modules.nixos.server = {
    services = {
      caddy = {
        enable = true;
        email = config.flake.meta.email;
      };
      telegram-alerts.units = [ "caddy" ];
    };
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
