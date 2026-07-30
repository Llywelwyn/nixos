{
  flake.modules.nixos.desktop = {
    services.earlyoom.enable = true;
    systemd.oomd.enable = false;
  };
}
