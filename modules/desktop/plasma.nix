{
  flake.modules.nixos.desktop = {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.xserver.xkb.layout = "gb";
  };
}
