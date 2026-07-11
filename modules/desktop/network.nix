{ config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    networking.networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    users.users.${config.flake.meta.username}.extraGroups = [ "networkmanager" ];
  };
}
