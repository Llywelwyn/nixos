{
  flake.modules.nixos.desktop = {
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };
    zramSwap.enable = true;
  };
}
