{ config, ... }:
{
  flake.modules.nixos.base = {
    users.users.${config.flake.meta.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = builtins.attrValues (import ../../keys);
    };
  };
}
