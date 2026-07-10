{
  flake.modules.nixos.server = {
    services.caddy.enable = true;
    services.caddy.email = "l@ily.rs";
    services.telegram-alerts.units = [ "caddy" ];
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
