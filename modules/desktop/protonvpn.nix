{
  flake.modules.nixos.desktop = {
    services.resolved.enable = true;
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = [ pkgs.proton-vpn ];
  };
}
