{ config, ... }:
{
  flake.modules.nixos.desktop = {
    networking.networkmanager.enable = true;
    users.users.${config.flake.meta.username}.extraGroups = [ "networkmanager" ];
  };
}
