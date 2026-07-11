{ config, inputs, ... }:
let
  inherit (config.flake.meta) username;
in
{
  flake.nixosConfigurations.vm0 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.server
      ./_vm0-hardware.nix
      {
        networking.hostName = "vm0";
        home-manager.users.${username}.home.stateVersion = "26.05";
        system.stateVersion = "23.11";
      }
    ];
  };
}
