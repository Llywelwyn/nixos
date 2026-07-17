{
  flake.modules.nixos.desktop = {
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 1048576;
    zramSwap.enable = true;
  };
}
