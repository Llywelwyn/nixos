{
  flake.modules.nixos.desktop = {
    nixpkgs.config.allowUnfree = true;
  };
}
