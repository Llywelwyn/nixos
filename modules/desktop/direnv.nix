{
  flake.modules.homeManager.desktop = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
