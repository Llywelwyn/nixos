{
  flake.modules.nixos.server = { lib, ... }:
  {
    services.telegram-alerts.units = [ "ergochat" ];

    services.ergochat = {
      enable = true;
      settings = {
        network.name = "ily";
        server = {
          name = "ily.rs";
          listeners = lib.mkForce { "127.0.0.1:6667" = { }; };
        };
      };
    };
  };
}
