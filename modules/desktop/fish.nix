{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    programs.fish.enable = true;
    users.users.l.shell = pkgs.fish;
  };

  flake.modules.homeManager.desktop = {
    programs.fish.enable = true;
  };
}
