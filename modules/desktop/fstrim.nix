{
  flake.modules.nixos.desktop = {
    services.fstrim.enable = true;
  };
}
