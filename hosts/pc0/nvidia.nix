{ ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false; # GTX 1080 is unsupported
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
