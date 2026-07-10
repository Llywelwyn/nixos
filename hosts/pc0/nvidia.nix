{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false; # GTX 1080 is unsupported
    # GTX 1080 (Pascal) was dropped from the mainline driver (595+);
    # it now needs the 580 legacy branch.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
