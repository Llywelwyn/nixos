{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      kate
      khelpcenter
      konsole
      krdp
      ktexteditor
      plasma-browser-integration
    ];

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
