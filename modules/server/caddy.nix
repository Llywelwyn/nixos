{
  flake.modules.nixos.server = {
    services = {
      caddy = {
        enable = true;
        email = "l@ily.rs";
      };
      telegram-alerts.units = [ "caddy" ];
    };
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
