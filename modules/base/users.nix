{
  flake.modules.nixos.base = {
    users.users.l = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = builtins.attrValues (import ../../keys);
    };
  };
}
