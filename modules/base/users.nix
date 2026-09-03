{ config, ... }:
{
  flake.modules.nixos.base = {
    users.users.${config.flake.meta.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETmIpkPkDLn21FuEA6n8WEQLzM3bfbMwiknkDtRbMhG pc0"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEfukxi9IGnne4uEQqGHER6d4d0HLq8flJApeqt/Lkag lew@ily.rs"
      ];
    };
  };
}
