{
  flake.modules.nixos.desktop = {
    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      desktopManager.plasma6.enable = true;
      xserver.xkb.layout = "gb";
    };
    console.useXkbConfig = true;
    security.rtkit.enable = true;
  };
}
