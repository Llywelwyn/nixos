{ config, ... }:
{
  flake.modules.nixos.server = { lib, ... }: {
    options.services.caddy.virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            logFormat = lib.mkDefault ''
              output file /var/log/caddy/access-${config.hostName}.log {
                roll_size 10MiB
                roll_keep 3
                roll_keep_for 30d
              }
            '';
          }
        )
      );
    };
    config = {
      services = {
        caddy = {
          enable = true;
          email = config.flake.meta.email;
        };
        telegram-alerts.units = [ "caddy" ];
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
  };
}
