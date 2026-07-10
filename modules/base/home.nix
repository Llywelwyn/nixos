{ config, inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
      users.l.imports = [ config.flake.modules.homeManager.base ];
    };
  };

  flake.modules.nixos.desktop = {
    home-manager.users.l.imports = [ config.flake.modules.homeManager.desktop ];
  };
}
